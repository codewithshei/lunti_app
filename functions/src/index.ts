import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Set admin role function - callable
export const setAdminRole = functions.https.onCall(async (data, context) => {
  // Security: Only admins can call this
  const caller = context.auth;
  if (caller == null) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }
  
  // Check if caller is already an admin (from custom claim)
  const callerToken = await admin.auth().verifyIdToken(caller.uid);
  if (callerToken.admin != true) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can set admin roles');
  }
  
  const { uid, isAdmin } = data;
  if (typeof uid !== 'string' || typeof isAdmin !== 'boolean') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid arguments');
  }
  
  await admin.auth().setCustomUserClaims(uid, { admin: isAdmin });
  
  return { success: true };
});

// Make user admin - bootstrap script helper
export const makeAdmin = functions.https.onCall(async (data, context) => {
  // Security: only an existing admin may grant the admin claim. Without this
  // any signed-in user could promote themselves (or anyone else).
  const caller = context.auth;
  if (caller == null) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const callerToken = await admin.auth().verifyIdToken(caller.uid);
  if (callerToken.admin != true) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can grant admin access');
  }

  const { uid } = data;
  if (typeof uid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'uid required');
  }
  
  await admin.auth().setCustomUserClaims(uid, { admin: true });
  
  console.log(`Made user ${uid} an admin`);
  return { success: true, message: `User ${uid} is now an admin` };
});

// Shell script helper functions
export const listUsers = functions.https.onCall(async (data, context) => {
  // Security: user listings expose emails, so they are admin-only.
  const caller = context.auth;
  if (caller == null) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const callerToken = await admin.auth().verifyIdToken(caller.uid);
  if (callerToken.admin != true) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can list users');
  }

  const list = await admin.auth().listUsers(100);
  return {
    users: list.users.map(u => ({ uid: u.uid, email: u.email, disabled: u.disabled })),
    nextPageToken: list.nextPageToken,
  };
});