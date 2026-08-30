const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}
const db = admin.firestore();

async function checkDishes() {
  const snapshot = await db.collection('global_dishes').limit(1).get();
  console.log(`Found ${snapshot.size} dishes`);
}

checkDishes().then(() => process.exit(0)).catch(console.error);
