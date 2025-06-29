// db/reminders.js
const { Firestore } = require('@google-cloud/firestore');
const db = new Firestore();

const col = db.collection('contest_reminders_sent');
async function hasSentReminder(contestId, tag) {
  const doc = await col.doc(`${contestId}_${tag}`).get();
  return doc.exists;
}
async function markSentReminder(contestId, tag) {
  await col.doc(`${contestId}_${tag}`)
    .set({ sentAt: Date.now() });
}
module.exports = { hasSentReminder, markSentReminder };
