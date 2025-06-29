// db/reminders.js
const { admin, db } = require('../firebase');

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
