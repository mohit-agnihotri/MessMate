const https = require('https');
const fs = require('fs');
const path = require('path');

const BACKUP_PATH = path.join(__dirname, 'dishes_backup.json');
const PROJECT_ID = 'mezzo-69cab';

if (!fs.existsSync(BACKUP_PATH)) {
  console.error('Backup file not found at:', BACKUP_PATH);
  process.exit(1);
}

const dishes = JSON.parse(fs.readFileSync(BACKUP_PATH, 'utf8'));
console.log(`Loaded ${dishes.length} dishes from backup.`);

function toFirestoreFields(d) {
  const fields = {};
  if (d.name) fields.name = { stringValue: String(d.name) };
  if (d.name_lower || d.name) {
    fields.name_lower = { stringValue: String(d.name_lower || d.name).toLowerCase() };
  }
  if (d.category) fields.category = { stringValue: String(d.category) };
  if (d.imageUrl) fields.imageUrl = { stringValue: String(d.imageUrl) };
  if (d.imageSource) fields.imageSource = { stringValue: String(d.imageSource) };
  if (d.searchKeywords && Array.isArray(d.searchKeywords)) {
    fields.searchKeywords = {
      arrayValue: {
        values: d.searchKeywords.map(k => ({ stringValue: String(k) }))
      }
    };
  }
  return fields;
}

function commitBatch(batchDishes) {
  return new Promise((resolve, reject) => {
    const writes = batchDishes.map(d => ({
      update: {
        name: `projects/${PROJECT_ID}/databases/(default)/documents/global_dishes/${d.id}`,
        fields: toFirestoreFields(d)
      }
    }));

    const postData = JSON.stringify({ writes });

    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents:commit`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(batchDishes.length);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function migrateAll() {
  const CHUNK_SIZE = 300;
  let totalUploaded = 0;

  for (let i = 0; i < dishes.length; i += CHUNK_SIZE) {
    const chunk = dishes.slice(i, i + CHUNK_SIZE);
    process.stdout.write(`Uploading chunk ${Math.floor(i / CHUNK_SIZE) + 1} (${chunk.length} dishes)... `);
    try {
      const count = await commitBatch(chunk);
      totalUploaded += count;
      console.log(`[OK] (${totalUploaded}/${dishes.length} completed)`);
    } catch (err) {
      console.error(`\nFailed on chunk ${Math.floor(i / CHUNK_SIZE) + 1}:`, err.message);
      throw err;
    }
  }

  console.log(`\n🎉 ALL ${totalUploaded} DISHES SUCCESSFULLY MIGRATED TO ${PROJECT_ID}!`);
}

migrateAll().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
