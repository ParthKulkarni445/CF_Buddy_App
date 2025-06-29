// sendReminder.js
// This module broadcasts contest reminder notifications to the 'contest-reminders' topic.

const admin = require('./firebase'); // Initialized Firebase Admin SDK

/**
 * Send a contest reminder to all devices subscribed to 'contest-reminders'.
 *
 * @param {string} contestName  - Name of the contest
 * @param {'8-hour'|'1-hour'} when - '8-hour' or '1-hour' reminder
 */
async function sendContestReminder(contestName, when) {
  const payload = {
    topic: 'contest-reminders',
    notification: {
      title: `Contest Reminder: ${contestName}`,
      body: when === '8-hour'
        ? 'Starts in 8 hours – get ready!'
        : 'Starts in 1 hour – good luck!'
    },
    data: {
      type: 'contest_reminder',
      contestName,
      when
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'contest_reminders' // must match channel ID in MainActivity.kt
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
