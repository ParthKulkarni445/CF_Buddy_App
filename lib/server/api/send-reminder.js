// /api/send-reminders.js

// 2. Your contest‑fetcher
const { fetchUpcomingContests } = require('../fetch_contests');
// 3. Your topic‑broadcaster
const { sendContestReminder } = require('../sendReminder');
// 4. A simple “sent” tracker in Firestore (or MongoDB)
const { hasSentReminder, markSentReminder, cleanupOldReminders } = require('../db/reminders');

module.exports = async (req, res) => {
  try {
    const now = Date.now();
    const contests = await fetchUpcomingContests();

    for (const contest of contests) {
      let id = contest.id;
      let name = contest.name;
      let startTimeMs = contest.startTimeMs;

      //Convert startTimeMs to IST time string
      const startTime = new Date(startTimeMs).toLocaleString('en-IN', {
        timeZone: 'Asia/Kolkata',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      });

      const hrsAway = (startTimeMs - now) / 3_600_000; 

      // 8‑hour window
      if (hrsAway > 7.99 && hrsAway < 8.01) {
        if (!(await hasSentReminder(id, '8h'))) {
          await sendContestReminder(name, '8-hour', startTime, id);
          await markSentReminder(id, '8h');
        }
      }

      // 1‑hour window
      if (hrsAway > 0 && hrsAway < 1.01) {
        if (!(await hasSentReminder(id, '1h'))) {
          await sendContestReminder(name, '1-hour', startTime, id);
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
