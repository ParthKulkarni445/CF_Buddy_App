// No more require('node-fetch')
// We rely on the built-in fetch (Node 18+ on Vercel)
async function fetchUpcomingContests() {
  // abort if CF API takes longer than 5s
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5_000);

  const res = await fetch(
    'https://codeforces.com/api/contest.list?gym=false',
    { signal: controller.signal }
  ).catch(err => {
    clearTimeout(timeout);
    throw new Error('CF API fetch failed: ' + err.message);
  });

  clearTimeout(timeout);

  if (!res.ok) {
    throw new Error(`CF API returned HTTP ${res.status}`);
  }

  const { result } = await res.json();
  return result
    .filter(c => c.phase === 'BEFORE')
    .map(c => ({
      id: c.id,
      name: c.name,
      startTimeMs: c.startTimeSeconds * 1000,
    }));
}

module.exports = { fetchUpcomingContests };