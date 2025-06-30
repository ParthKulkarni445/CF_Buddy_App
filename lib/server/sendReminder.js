// sendReminder.js
// This module broadcasts contest reminder notifications to the 'contest-reminders' topic.

const { admin, db } = require('./firebase'); // Initialized Firebase Admin SDK

async function sendContestReminder(contestName, when, startTime, contestId) {
  const title = '📢 CF Contest Alert';
  const body = `${contestName} is set to start at ${startTime}! ${when === '8-hour'
    ? '💪 Sharpen your greed, boost your speed and get ready for it! Click to register.'
    : '🔥 You’ve got this! Go show those test cases who’s boss! Click to register.'}`;

  const payload = {
    topic: 'contest-reminders',
    notification: {
      title,
      body,
    },
    data: {contestId},
    android: {
      priority: 'high',
      notification: {
        channelId: 'contest_reminders', // must match channel ID in MainActivity.kt
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        icon: 'ic_stat_contest_reminder', // your notification icon
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
