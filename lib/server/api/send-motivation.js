const { admin, db } = require('../firebase'); // Initialized Firebase Admin SDK

async function sendMotivativeThoughts() {
  const titles = [
  "AC hi AC hoga 🎯",
  "Kitne test cases the? 🤔",
  "Nahi tu nahi samjha! 😜",
  "Ye WA khatam kyu nai hota! 🔥",
  "Kehna kya chahte ho? 💬",
  "Kya gunda banega re tu?⚡️",
  "Toh kar na! Submit kar na! 🚀",
  "Ctrl Uday, Ctrl+Z fir Ctrl+Y!⌨️",
  "Miracle, Miracle! ✨",
  "Adbhut… 7 crore ke TC! 🤑",
  "Cheating karta h tu! 🤫",
  "Phodega nahi to chhodega nahi! 💥",
  "Kya mai mar jaun? 😅",
  "Emotional Damage? 💔",
  "Kuch to gadbad hai, Daya! 🐞",
  "Mast plan hai! 📝",
  "Ab maza ayega na bidu! 🎉",
  "Aag laga di, aag laga di! 🔥",
  "150 ms dega... 📈",
  "50th TC fail? Overacting ki? 🎭",
  "Ptr ka chakkar, babu bhaiya! 🕵️‍♂️"
];

const thoughts = [
  "Consistency is king: schedule short daily sessions focusing on one algorithm or data structure, and you’ll see WA rates plummet. 💪",
  "Before you code, write down every possible edge case—nulls, bounds, weird inputs—then tick them off as you test. 📝",
  "If the statement still feels fuzzy, rephrase it in your own words or draw a quick diagram; clarity here saves hours of debugging. 📖",
  "When a WA strikes, log variable states at key points rather than guessing—systematic inspection finds the culprit faster. 🔍",
  "Decide upfront if you need a greedy, DP, or graph approach; picking the right paradigm early prevents wasted rewrites. 🧭",
  "Benchmark simple vs. advanced algorithms on sample sizes—if O(n²) passes small tests but TLEs on large, upgrade your approach. 🚀",
  "Adopt the ‘compile–test’ cycle: after each code block, compile and run a custom test to catch typos before they compound. ⏱️",
  "Use Git or local commits as checkpoints—when you introduce a bug, rollback to the last green commit and compare diffs. 🔄",
  "Transform every WA into actionable feedback: identify the test that failed, hypothesize the bug, implement, and retest immediately. ✨",
  "Simulate judge behavior: feed your solution randomized and boundary tests via scripts to catch hidden pitfalls. 👀",
  "Maintain snippets for frequent patterns—binary search templates, DSU setups—but always adapt variable names and conditions. 📂",
  "Don’t settle after a single fix; once your code passes, refactor for readability and annotate complex logic for future you. ✅",
  "Track your WA-to-AC ratio over time—aim to shrink the gap by reviewing problems you struggled with into a personal knowledge base. 📈",
  "View each failure as an experiment: log the input, your output, and the expected output to learn patterns in your mistakes. 🔥",
  "Adopt a divide‑and‑conquer debug style: isolate the smallest failing segment, write a minimal repro, and fix at that scope. 🛠️",
  "Outline with pseudocode and talk through it aloud—verbalizing logic often exposes flawed assumptions before you type. ✍️",
  "Celebrate small wins: every passed test case is data confirming your logic; use that momentum to tackle the next challenge. 🎊",
  "Your code’s on fire—keep that blaze green by profiling hotspots and optimizing loops to dodge TLEs! 🔥",
  "Estimate time complexity in comments alongside your code blocks, so you’re always aware of potential TLE traps. ⏳",
  "Automate batch testing: write a script that runs dozens of test files in seconds—avoid manual copy-paste drudgery. 🧪",
  "Deep dive pointers: draw memory diagrams on paper to visualize references and prevent off-by-one or null deref bugs. 🎯"
];

const randomIdx = Math.floor(Math.random() * thoughts.length);
const randomTitle = titles[randomIdx];
const randomThought = thoughts[randomIdx];

  const payload = {
    topic: 'motivation',
    notification: {
      title: randomTitle,
      body: randomThought,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'motivation_channel', // must match channel ID in MainActivity.kt
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        icon: 'ic_stat_reminder', // your notification icon
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
    console.log(`Motivational message sent successfully: ${response}`);
  } catch (error) {
    console.error('Error sending motivational message:', error);
    throw error;
  }
}   

module.exports = async ( req, res ) => {
    try{
        await sendMotivativeThoughts();
        return res.status(200).send('Motivational message sent');
    } catch (err) {
        console.error('Error in send-motivation:', err);
        return res.status(500).send('Internal error');
    }
};