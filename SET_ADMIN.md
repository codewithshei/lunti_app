# Making a User Admin

## Option 1: Firebase Console (Manual)

1. Go to Firebase Console → Authentication → Users
2. Find your test user (uid: `cecRlsDx6mhvr5Dey6phRihiiIh2`)
3. Click the three dots → **Edit**
4. Add custom claim: `{"admin": true}`
5. Click **Save**

**Note:** Firebase Console only supports JSON claims for simple values. After adding, have the user sign out and sign back in to refresh the token.

## Option 2: Firebase Emulator Suite (Development)

```bash
# From project root
npm install -g firebase-tools
firebase login
firebase use lunti-admin

# Set the admin claim
firebase auth:export /tmp/users.json --format=json
# Edit the JSON to add admin claim, then import
firebase auth:import /tmp/users.json --hash-algo=NONE
```

## Option 3: Using the Shell Script (Local)

1. Clone your Firebase service account key to `functions/service-account.json`
2. Set the environment variable:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="functions/service-account.json"
   ```
3. Run:
   ```bash
   cd functions
   npx ts-node scripts/make-admin.ts cecRlsDx6mhvr5Dey6phRihiiIh2
   ```

## Option 4: Callable Function (After Deployment)

After deploying functions, call from client:
```javascript
import { httpsCallable } from 'firebase/functions';

const makeAdmin = httpsCallable(functions, 'makeAdmin');
await makeAdmin({ uid: 'cecRlsDx6mhvr5Dey6phRihiiIh2' });
```

The user will need to sign out and sign back in for the admin claim to take effect.