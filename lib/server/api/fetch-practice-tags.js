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

/**
 * Returns all tracked user handles from Firestore.
 */
async function getAllTrackedHandles() {
  const snap = await db.collection('users').get();
  const handles = [];
  snap.forEach(doc => {
    const data = doc.data();
    if (data.handle) handles.push(data.handle);
  });
  return handles;
}

/**
 * Processes contest standings only for tracked handles.
 */
async function processContestStandings(contestId, trackedHandles) {
  console.log(`\n>>> [Contest ${contestId}] Starting processContestStandings`);
  console.time(`Contest ${contestId} - Total Time`);

  // 1. Chunk tracked handles for Codeforces API (max 100 per call)
  const handleChunks = chunkArray(trackedHandles, 100);

  // 2. Build a map: handle -> Firestore doc reference (+tags)
  const handleToEntry = new Map();
  for (const batch of chunkArray(trackedHandles, 10)) {
    const snap = await db.collection('users').where('handle', 'in', batch).get();
    snap.docs.forEach(doc => {
      const data = doc.data();
      handleToEntry.set(data.handle, {
        ref: doc.ref,
        tags: new Set(data.practiceTags || []),
      });
    });
  }

  // 3. For each chunk, fetch standings and process results
  for (const chunk of handleChunks) {
    const url = `https://codeforces.com/api/contest.standings?contestId=${contestId}&handles=${chunk.join(';')}`;
    console.time(`Contest ${contestId} - Fetch Standings (${chunk.length})`);
    const resp = await fetch(url);
    console.log(chunk.join(';'));
    if (!resp.ok) {
      console.error(`[Contest ${contestId}] Error fetching standings for chunk: ${resp.statusText}`);
      continue;
    }
    const data = await resp.json();
    console.timeEnd(`Contest ${contestId} - Fetch Standings (${chunk.length})`);
    const result = data.result;
    const rows = result.rows;
    const problems = result.problems;
    const totalParticipants = rows.length;

    // 4. Precompute solve counts for this chunk
    const solveCounts = rows.reduce((counts, r) => {
      r.problemResults.forEach((pr, idx) => {
        if (pr.points > 0) counts[idx] = (counts[idx] || 0) + 1;
      });
      return counts;
    }, {});

    // 5. Prepare Firestore batch writes (max 500 per batch)
    let batchOps = 0;
    let writeBatch = db.batch();

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
        practiceTags: Array.from(entry.tags),
      });
      batchOps++;
      // Commit batch if reaching Firestore batch limit
      if (batchOps === 500) {
        writeBatch.commit();
        writeBatch = db.batch();
        batchOps = 0;
      }
    });
    // Commit any remaining ops
    if (batchOps > 0) await writeBatch.commit();
  }

  console.timeEnd(`Contest ${contestId} - Total Time`);
  console.log(`<<< [Contest ${contestId}] Finished processContestStandings`);
}

export default async (req, res) => {
  console.log('### Starting fetch-practice-tags function');
  console.time('fetch-practice-tags - Total Time');

  try {
    // 1. Fetch all tracked handles
    const trackedHandles = await getAllTrackedHandles();
    if (trackedHandles.length === 0) throw new Error('No tracked handles found.');

    // 2. Fetch contest list
    const resp = await fetch('https://codeforces.com/api/contest.list?gym=false');
    if (!resp.ok) throw new Error(`CF contest.list fetch failed: ${resp.statusText}`);
    const { result: contests } = await resp.json();

    // 3. Filter & sort last finished contest (or more if you want)
    const finished = contests
      .filter(c => c.phase === 'FINISHED')
      .sort((a, b) => b.startTimeSeconds - a.startTimeSeconds)
      .slice(0, 1);

    // 4. Process all contests in parallel (if more than one)
    await Promise.all(finished.map(c => processContestStandings(c.id, trackedHandles)));

    console.timeEnd('fetch-practice-tags - Total Time');
    console.log('### Completed fetch-practice-tags function');
    res.status(200).send('Practice tags updated for tracked users in last finished contest.');
  } catch (err) {
    console.error('fetch-practice-tags function error:', err);
    console.timeEnd('fetch-practice-tags - Total Time');
    res.status(500).send('Internal server error');
  }
};