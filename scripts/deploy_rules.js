const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');
const https = require('https');
const fs = require('fs');
const path = require('path');

const rulesPath = path.join(__dirname, '..', 'firestore.rules');
let rules = fs.readFileSync(rulesPath, 'utf8');

if (!rules.includes('meal_plans')) {
  const insertPos = rules.indexOf('match /dishes/{dishId}');
  const toInsert = '      match /meal_plans/{planId} {\n' +
    '        allow read: if request.auth != null;\n' +
    '        allow write: if request.auth != null;\n' +
    '      }\n\n' +
    '      match /extra_fees/{feeId} {\n' +
    '        allow read: if request.auth != null;\n' +
    '        allow write: if request.auth != null;\n' +
    '      }\n\n';
  rules = rules.slice(0, insertPos) + toInsert + rules.slice(insertPos);
  fs.writeFileSync(rulesPath, rules, 'utf8');
  console.log('Saved updated firestore.rules locally');
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(sa) });
}

admin.app().options.credential.getAccessToken().then(token => {
  const payload = JSON.stringify({
    source: {
      files: [{ name: 'firestore.rules', content: rules }]
    }
  });
  const req = https.request({
    hostname: 'firebaserules.googleapis.com',
    path: '/v1/projects/mezzo-69cab/rulesets',
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + token.access_token,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload)
    }
  }, res => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('Create ruleset status:', res.statusCode);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        const parsed = JSON.parse(data);
        const rulesetName = parsed.name;
        console.log('Created ruleset:', rulesetName);
        const releasePayload = JSON.stringify({
          release: {
            name: 'projects/mezzo-69cab/releases/cloud.firestore',
            rulesetName: rulesetName
          }
        });
        const patchReq = https.request({
          hostname: 'firebaserules.googleapis.com',
          path: '/v1/projects/mezzo-69cab/releases/cloud.firestore',
          method: 'PATCH',
          headers: {
            'Authorization': 'Bearer ' + token.access_token,
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(releasePayload)
          }
        }, patchRes => {
          let pData = '';
          patchRes.on('data', chunk => pData += chunk);
          patchRes.on('end', () => console.log('Release updated status:', patchRes.statusCode, pData));
        });
        patchReq.write(releasePayload);
        patchReq.end();
      } else {
        console.error('Error creating ruleset:', data);
      }
    });
  });
  req.write(payload);
  req.end();
}).catch(err => console.error(err));
