import { db } from '../firebase.js';

/**
 * Utility to chunk an array into smaller arrays of given size.
 */
function chunkArray(arr, size) {
  const chunks = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

async function processContestStandings(contestId) {
  // 1. Fetch standings
  const resp = await fetch(`https://codeforces.com/api/contest.standings?contestId=${contestId}`);
  if (!resp.ok) {
    throw new Error(`CF standings fetch failed: ${resp.statusText}`);
  }
  const { result } = await resp.json();
  const rows = result.rows;
  const problems = result.problems;
  const totalParticipants = rows.length;

  // 2. Precompute solve counts once
  const solveCounts = rows.reduce((counts, r) => {
    r.problemResults.forEach((pr, idx) => {
      if (pr.points > 0) counts[idx] = (counts[idx] || 0) + 1;
    });
    return counts;
  }, {});

  // 3. Gather all handles
  const handles = rows
    .map(r => r.party.members?.[0]?.handle)
    .filter(Boolean);

  if (handles.length === 0) {
    return; // nothing to do
  }

  // 4. Bulk‑fetch user docs in chunks of 10
  const handleToEntry = new Map();
  const batches = chunkArray(handles, 10);
  for (const batch of batches) {
    const snap = await db
      .collection('users')
      .where('handle', 'in', batch)
      .get();
    snap.docs.forEach(doc => {
      const data = doc.data();
      handleToEntry.set(data.handle, {
        ref: doc.ref,
        tags: new Set(data.practiceTags || [])
      });
    });
  }

  // 5. Build a single Firestore write batch
  const writeBatch = db.batch();

  // 6. For each row, update its tag set in the batch
  rows.forEach(row => {
    const handle = row.party.members?.[0]?.handle;
    const entry = handleToEntry.get(handle);
    if (!entry) return;

    problems.forEach((problem, idx) => {
      const pr = row.problemResults[idx];
      const solved = pr.points > 0;
      const failed = pr.failedAttemptCount > 0;
      const sc = solveCounts[idx] || 0;

      // apply your “unsolved or failed on a rare problem” rule
      if (failed || (!solved && sc <= 0.1 * totalParticipants)) {
        (problem.tags || []).forEach(tag => entry.tags.add(tag));
      }
    });

    writeBatch.update(entry.ref, {
      practiceTags: Array.from(entry.tags)
    });
  });

  // 7. Commit all updates in one go
  await writeBatch.commit();
}

export default async (req, res) => {
  try {
    // fetch last 5 finished contests
    const resp = await fetch('https://codeforces.com/api/contest.list?gym=false');
    if (!resp.ok) {
      throw new Error(`CF contest.list fetch failed: ${resp.statusText}`);
    }
    const { result: contests } = await resp.json();
    const finished = contests
      .filter(c => c.phase === 'FINISHED')
      .sort((a, b) => b.startTimeSeconds - a.startTimeSeconds)
      .slice(0, 5);

    // process all 5 in parallel (bounded only by CF rate‑limits)
    await Promise.all(finished.map(c => processContestStandings(c.id)));

    res.status(200).send('Practice tags updated for last 5 finished contests');
  } catch (err) {
    console.error('Error in CF tag‑updater function:', err);
    res.status(500).send('Internal server error');
  }
};
