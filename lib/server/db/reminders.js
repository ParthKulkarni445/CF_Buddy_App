// db/reminders.js
const { db } = require('../firebase');

const col = db.collection('contest_reminders_sent');
async function hasSentReminder(contestId, tag) {
  const doc = await col.doc(`${contestId}_${tag}`).get();
  return doc.exists;
}

async function cleanupOldReminders() {
  const cutoff = Date.now() - 15 * 60 * 1000; // 15 minutes
  const snapshot = await col.where('sentAt', '<', cutoff).get();
  if (snapshot.empty) return;
  const batch = db.batch();
  snapshot.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
}

async function markSentReminder(contestId, tag) {
  await col.doc(`${contestId}_${tag}`)
    .set({ sentAt: Date.now() });
}
module.exports = { hasSentReminder, markSentReminder, cleanupOldReminders };
