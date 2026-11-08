#!/usr/bin/env npx ts-node

/**
 * Bootstrap script to make a user an admin.
 * 
 * Usage:
 *   1. Set GOOGLE_APPLICATION_CREDENTIALS to your service account key
 *   2. Run: npx ts-node scripts/make-admin.ts <uid>
 * 
 * This script bypasses client-side security and directly sets the custom claim.
 */

import * as admin from 'firebase-admin';

// Initialize admin app with default credentials
admin.initializeApp();

async function makeAdmin(uid: string) {
  try {
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    console.log(`✅ Success! User ${uid} is now an admin.`);
    console.log('You can now sign in as this user in the admin dashboard.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error making user admin:', error);
    process.exit(1);
  }
}

// Get UID from command line
const args = process.argv.slice(2);
if (args.length === 0) {
  console.log('Usage: npx ts-node scripts/make-admin.ts <uid>');
  console.log('Or: deno run --allow-all scripts/make-admin.ts <uid>');
  process.exit(1);
}

const uid = args[0];
makeAdmin(uid);