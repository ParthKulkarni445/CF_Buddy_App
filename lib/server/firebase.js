// firebase.js
const admin = require("firebase-admin");
const serviceAccount = JSON.parse(process.env.FIREBASE_KEY);;

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Export both the admin and Firestore instance
const db = admin.firestore();

module.exports = { admin, db };
