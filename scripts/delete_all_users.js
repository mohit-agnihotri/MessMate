const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const auth = admin.auth();

const PRESERVED_COLLECTIONS = new Set(['global_dishes', 'system_config']);

const KNOWN_COLLECTIONS = [
  'messes', 'students', 'meal_records', 'bills', 'announcements',
  'feedbacks', 'leaves', 'menus', 'closed_slots', 'weekly_templates',
  'mess_photos', 'meal_plans', 'extra_fees', 'users', 'preferences', 'dishes', 'support_tickets'
];

async function deleteAllAuthUsers() {
  let totalDeleted = 0;
  let nextPageToken;
  do {
    const listResult = await auth.listUsers(1000, nextPageToken);
    const uids = listResult.users.map(u => u.uid);
    if (uids.length === 0) break;
    console.log(`Deleting ${uids.length} Firebase Auth user(s)...`);
    for (const u of listResult.users) {
      console.log(`  - ${u.email} (${u.uid})`);
    }
    const result = await auth.deleteUsers(uids);
    totalDeleted += result.successCount;
    if (result.failureCount > 0) {
      console.warn(`  Failed to delete ${result.failureCount} users`);
    }
    nextPageToken = listResult.pageToken;
  } while (nextPageToken);
  console.log(`✓ Firebase Auth: Deleted ${totalDeleted} user account(s).`);
}

async function cleanFirestore() {
  const rootCollections = await db.listCollections();
  const allCollectionNames = new Set([
    ...rootCollections.map(c => c.id),
    ...KNOWN_COLLECTIONS
  ]);

  for (const colName of allCollectionNames) {
    if (PRESERVED_COLLECTIONS.has(colName)) {
      console.log(`• Preserving [${colName}] (safe collection)`);
      continue;
    }

    const colRef = db.collection(colName);
    const sample = await colRef.limit(1).get();
    if (sample.empty) {
      console.log(`• [${colName}] is already empty.`);
      continue;
    }

    console.log(`• Recursively deleting [${colName}] (including subcollections)...`);
    await db.recursiveDelete(colRef);
    console.log(`✓ [${colName}] completely deleted.`);
  }
}

async function main() {
  console.log('==============================================');
  console.log('  MESSMATE: RESET ALL USERS & MESS DATA');
  console.log('==============================================');
  console.log('\n--- Step 1: Deleting Firebase Auth Users ---');
  await deleteAllAuthUsers();

  console.log('\n--- Step 2: Deleting Firestore Collections & Subcollections ---');
  await cleanFirestore();

  console.log('\n==============================================');
  console.log('  RESET COMPLETE!');
  console.log('  - All users deleted from Firebase Auth.');
  console.log('  - All mess & student data wiped from Firestore.');
  console.log('  - [global_dishes] library is 100% safe & intact.');
  console.log('  You can now register/test fresh with the same Gmail IDs.');
  console.log('==============================================\n');
  process.exit(0);
}

main().catch(err => {
  console.error('Fatal Error:', err);
  process.exit(1);
});