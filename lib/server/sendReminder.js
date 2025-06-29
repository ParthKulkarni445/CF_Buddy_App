// sendReminder.js
// This module broadcasts contest reminder notifications to the 'contest-reminders' topic.

const { admin, db } = require('./firebase'); // Initialized Firebase Admin SDK

/**
 * Send a contest reminder to all devices subscribed to 'contest-reminders'.
 *
 * @param {string} contestName  - Name of the contest
 * @param {'8-hour'|'1-hour'} when - '8-hour' or '1-hour' reminder
 * @param {string} startTime - Start time of the contest in IST
 */
async function sendContestReminder(contestName, when, startTime) {
  const payload = {
    topic: 'contest-reminders',
    notification: {
      title: `📢 CF Contest Alert`,
      body: `${contestName} is set to start at ${startTime}! ${when === '8-hour' ? 
        '💪 Sharpen your greed, boost your speed and don\'t forget to register!' 
        : '🔥 You’ve got this! Go show those test cases who’s boss!'} `,
    },
    data: {
      type: 'contest_reminder',
      contestName,
      when
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'contest_reminders', // must match channel ID in MainActivity.kt
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        icon: 'ic_stat_contest_reminder', // your notification icon
        actions: [
          {
            title: 'View Contest',
            action: 'VIEW_CONTEST',
          }
        ]
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(payload);
    console.log(`Topic message sent successfully: ${response}`);
  } catch (error) {
    console.error('Error sending topic reminder:', error);
    throw error;
  }
}

module.exports = { sendContestReminder };
