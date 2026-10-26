const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const adminEmails = [
  'agnihotrimohit185@gmail.com'
];

async function setAdminClaims() {
  console.log('--- Setting Admin Custom Claims ---');
  for (const email of adminEmails) {
    try {
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().setCustomUserClaims(user.uid, { admin: true });
      console.log(`[SUCCESS] Stamped { admin: true } claim on: ${email} (${user.uid})`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        console.log(`[SKIPPED] User not found yet: ${email}`);
      } else {
        console.error(`[ERROR] Failed to set claim for ${email}:`, e.message);
      }
    }
  }
  console.log('--- Done Setting Claims ---');
}

setAdminClaims().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
