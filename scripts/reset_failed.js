const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}
const db = admin.firestore();

async function resetFailed() {
  console.log('Resetting google_failed dishes...');
  const snapshot = await db.collection('global_dishes').where('imageSource', '==', 'google_failed').get();
  const batch = db.batch();
  
  let count = 0;
  snapshot.forEach(doc => {
    batch.update(doc.ref, { imageSource: 'pexels' }); // reset back to default so updater can pick it up
    count++;
  });
  
  if(count > 0) {
     await batch.commit();
     console.log(`Reset ${count} dishes successfully!`);
  } else {
     console.log('No failed dishes found to reset.');
  }
}

resetFailed().then(() => process.exit(0)).catch(console.error);
