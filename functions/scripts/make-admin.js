// Simple script to set admin custom claim
// Usage: node scripts/make-admin.js <uid>

const admin = require('firebase-admin');
const path = require('path');

// Initialize with service account
const serviceAccount = require('./service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const uid = process.argv[2];
if (!uid) {
  console.error('Usage: node scripts/make-admin.js <uid>');
  process.exit(1);
}

admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log(`✅ Success! User ${uid} is now an admin.`);
    console.log('The user will see the changes after signing out and back in.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error making user admin:', error.message);
    process.exit(1);
  });