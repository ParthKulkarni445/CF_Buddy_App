import { db } from '../firebase.js';
import { performance } from 'perf_hooks';

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
  console.log(`\n>>> [Contest ${contestId}] Starting processContestStandings`);
  console.time(`Contest ${contestId} - Total Time`);

  // 1. Fetch standings
  console.time(`Contest ${contestId} - Fetch Standings`);
  const resp = await fetch(`https://codeforces.com/api/contest.standings?contestId=${contestId}`);
  if (!resp.ok) {
    console.error(`Contest ${contestId} - Error fetching standings: ${resp.statusText}`);
    throw new Error(`CF standings fetch failed: ${resp.statusText}`);
  }
  const data = await resp.json();
  console.timeEnd(`Contest ${contestId} - Fetch Standings`);

  const result = data.result;
  const rows = result.rows;
  const problems = result.problems;
  const totalParticipants = rows.length;

  // 2. Precompute solve counts
  console.time(`Contest ${contestId} - Compute solveCounts`);
  const solveCounts = rows.reduce((counts, r) => {
    r.problemResults.forEach((pr, idx) => {
      if (pr.points > 0) counts[idx] = (counts[idx] || 0) + 1;
    });
    return counts;
  }, {});
  console.timeEnd(`Contest ${contestId} - Compute solveCounts`);

  // 3. Gather all handles
  console.time(`Contest ${contestId} - Gather Handles`);
  const handles = rows
    .map(r => r.party.members?.[0]?.handle)
    .filter(Boolean);
  console.timeEnd(`Contest ${contestId} - Gather Handles`);

  if (handles.length === 0) {
    console.log(`Contest ${contestId} - No handles found, skipping.`);
    console.timeEnd(`Contest ${contestId} - Total Time`);
    return;
  }

  // 4. Bulk-fetch user docs in chunks of 10
  console.time(`Contest ${contestId} - Bulk Fetch Users`);
  const handleToEntry = new Map();
  const batches = chunkArray(handles, 10);
  for (const batch of batches) {
    console.time(`Contest ${contestId} - Query Batch (${batch.length})`);
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
    console.timeEnd(`Contest ${contestId} - Query Batch (${batch.length})`);
  }
  console.timeEnd(`Contest ${contestId} - Bulk Fetch Users`);

  // 5. Build a single Firestore write batch
  console.time(`Contest ${contestId} - Build & Commit Batch`);
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

      if (failed || (!solved && sc <= 0.1 * totalParticipants)) {
        (problem.tags || []).forEach(tag => entry.tags.add(tag));
      }
    });

    writeBatch.update(entry.ref, {
      practiceTags: Array.from(entry.tags)
    });
  });

  await writeBatch.commit();
  console.timeEnd(`Contest ${contestId} - Build & Commit Batch`);

  console.timeEnd(`Contest ${contestId} - Total Time`);
  console.log(`<<< [Contest ${contestId}] Finished processContestStandings`);
}

export default async (req, res) => {
  console.log('### Starting fetch-practice-tags function');
  console.time('fetch-practice-tags - Total Time');

  try {
    // 1. Fetch contest list
    console.time('fetch-practice-tags - Fetch Contests');
    const resp = await fetch('https://codeforces.com/api/contest.list?gym=false');
    if (!resp.ok) {
      console.error('Error fetching contests:', resp.statusText);
      throw new Error(`CF contest.list fetch failed: ${resp.statusText}`);
    }
    const { result: contests } = await resp.json();
    console.timeEnd('fetch-practice-tags - Fetch Contests');

    // 2. Filter & sort last 5 finished contests
    console.time('fetch-practice-tags - Filter & Sort Contests');
    const finished = contests
      .filter(c => c.phase === 'FINISHED')
      .sort((a, b) => b.startTimeSeconds - a.startTimeSeconds)
      .slice(0, 5);
    console.timeEnd('fetch-practice-tags - Filter & Sort Contests');

    // 3. Process all contests in parallel
    console.time('fetch-practice-tags - Process All Contests');
    await Promise.all(finished.map(c => processContestStandings(c.id)));
    console.timeEnd('fetch-practice-tags - Process All Contests');

    console.timeEnd('fetch-practice-tags - Total Time');
    console.log('### Completed fetch-practice-tags function');
    res.status(200).send('Practice tags updated for last 5 finished contests');
  } catch (err) {
    console.error('fetch-practice-tags function error:', err);
    console.timeEnd('fetch-practice-tags - Total Time');
    res.status(500).send('Internal server error');
  }
};
