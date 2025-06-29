// fetchContests.js
const fetch = require('node-fetch');

async function fetchUpcomingContests() {
  const res = await fetch('https://codeforces.com/api/contest.list?gym=false');
  const { result } = await res.json();
  // filter only future contests
  return result
    .filter(c => c.phase === 'BEFORE')
    .map(c => ({
      id: c.id,
      name: c.name,
      startTime: c.startTimeSeconds * 1000  // JS timestamp ms
    }));
}

module.exports = { fetchUpcomingContests };