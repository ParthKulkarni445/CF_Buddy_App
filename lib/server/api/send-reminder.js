// /api/send-reminders.js

// 1. Initialize your Firebase Admin 
const admin = require('../firebase');      // ← make sure this path matches your project
// 2. Your contest‑fetcher
const { fetchUpcomingContests } = require('../fetch_contests');
// 3. Your topic‑broadcaster
const { sendContestReminder } = require('../sendReminder');
// 4. A simple “sent” tracker in Firestore (or MongoDB)
const { hasSentReminder, markSentReminder } = require('../db/reminders');

module.exports = async (req, res) => {
  try {
    const now = Date.now();
    const contests = await fetchUpcomingContests(); // [{ id, name, startTimeMs }, …]
    console.log('  got', contests.length, 'upcoming contests');


    for (const contest of contests) {
      let id = contest.id;
      let name = contest.name;
      let startTimeMs = contest.startTimeMs;

      startTimeMs=1751192700000;
      name='Codeforces Round #123 (Div. 2)';
      id='1900';

      const hrsAway = (startTimeMs - now) / 3_600_000; // convert ms to hours
      console.log(`  ${name} starts in ${hrsAway.toFixed(2)} hours`);
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
