// /api/send-reminders.js

// 1. Initialize your Firebase Admin 
const admin = require('../server/firebase');      // ← make sure this path matches your project
// 2. Your contest‑fetcher
const { fetchUpcomingContests } = require('../server/fetch_contests');
// 3. Your topic‑broadcaster
const { sendContestReminder } = require('../server/sendReminder');
// 4. A simple “sent” tracker in Firestore (or MongoDB)
const { hasSentReminder, markSentReminder } = require('../server/db/reminders');

module.exports = async (req, res) => {
  try {
    const now = Date.now();
    const contests = await fetchUpcomingContests(); // [{ id, name, startTimeMs }, …]

    for (const { id, name, startTimeMs } of contests) {
      const hrsAway = (startTimeMs - now) / 3_600_000; // hours

      // 8‑hour window
      if (hrsAway > 7.99 && hrsAway < 8.01) {
        if (!(await hasSentReminder(id, '8h'))) {
          await sendContestReminder(name, '8-hour');
          await markSentReminder(id, '8h');
        }
      }

      // 1‑hour window
      if (hrsAway > 0.99 && hrsAway < 1.01) {
        if (!(await hasSentReminder(id, '1h'))) {
          await sendContestReminder(name, '1-hour');
          await markSentReminder(id, '1h');
        }
      }
    }

    return res.status(200).send('Reminders checked');
  } catch (err) {
    console.error('Error in send-reminders:', err);
    return res.status(500).send('Internal error');
  }
};
