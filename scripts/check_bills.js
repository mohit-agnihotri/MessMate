const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}
const db = admin.firestore();

async function checkBills() {
  const snapshot = await db.collection('bills').get();
  console.log(`Found ${snapshot.size} bills`);
  snapshot.forEach(doc => {
    console.log(doc.id, '=>', doc.data());
  });
}

checkBills().then(() => process.exit(0)).catch(console.error);
