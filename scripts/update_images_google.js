require('dotenv').config();
const admin = require('firebase-admin');
const fetch = require('node-fetch');

// -- Firebase Init
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();
const COLLECTION = 'global_dishes';

// -- Config
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
const GOOGLE_CX = process.env.GOOGLE_CX; // Search Engine ID
const DAILY_LIMIT = 100;
const DELAY_MS = 1000; // polite delay

if (!GOOGLE_API_KEY || !GOOGLE_CX) {
  console.error('ERROR: GOOGLE_API_KEY or GOOGLE_CX not set in .env file.');
  console.error('Please add them to your .env file.');
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchGoogleImage(dishName) {
  const query = encodeURIComponent(dishName + ' Indian recipe sabzi food');
  const url = `https://www.googleapis.com/customsearch/v1?q=${query}&cx=${GOOGLE_CX}&key=${GOOGLE_API_KEY}&searchType=image&num=1`;
  
  try {
    const res = await fetch(url);
    const data = await res.json();
    
    if (data.error && data.error.code === 429) {
      console.error('  ERROR: Google API Rate Limit Exceeded (429)!');
      return 'RATE_LIMIT';
    }

    if (data.items && data.items.length > 0) {
      return data.items[0].link;
    }
    return null;
  } catch (e) {
    console.warn('  Network error for ' + dishName + ': ' + e.message);
    return null;
  }
}

async function runGoogleUpdater() {
  console.log(`Starting Google Image Updater. Target: Next ${DAILY_LIMIT} dishes.`);
  
  // We query for dishes where 'imageSource' is NOT 'google'. 
  // We'll fetch them all, then filter locally, or just query without a filter and check inside.
  // The easiest is to query documents that don't have the imageSource field set to 'google'.
  
  const snap = await db.collection(COLLECTION).get();
  
  let processed = 0;
  let updated = 0;
  let failed = 0;

  for (const doc of snap.docs) {
    if (processed >= DAILY_LIMIT) {
      console.log(`\nReached daily limit of ${DAILY_LIMIT}. Stopping for today.`);
      break;
    }

    const data = doc.data();
    
    // Skip if it was already updated by Google
    if (data.imageSource === 'google') {
      continue; 
    }

    console.log(`[${processed + 1}/${DAILY_LIMIT}] Fetching Google Image for: ${data.name}`);
    const imageUrl = await fetchGoogleImage(data.name);

    if (imageUrl === 'RATE_LIMIT') {
      console.log('Daily quota likely reached. Exiting script.');
      break;
    }

    if (imageUrl) {
      // Update document with new image and flag it as google sourced
      await doc.ref.update({ 
        imageUrl: imageUrl,
        imageSource: 'google',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log('  -> UPDATED: ' + imageUrl);
      updated++;
    } else {
      console.warn('  -> FAIL: No image found.');
      // Still mark it as google so we don't infinitely retry failing queries
      await doc.ref.update({ imageSource: 'google_failed' });
      failed++;
    }

    processed++;
    await sleep(DELAY_MS);
  }

  console.log(`\nUpdate complete for today!`);
  console.log(`Processed: ${processed} | Updated: ${updated} | Failed/Not Found: ${failed}`);
  process.exit(0);
}

runGoogleUpdater().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});
