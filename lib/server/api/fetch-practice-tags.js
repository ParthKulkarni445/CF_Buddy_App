import { db } from '../firebase.js';

async function processContestStandings(contestId) {
    try{
        const response = await fetch(`https://codeforces.com/api/contest.standings?contestId=${contestId}`);
        if (!response.ok) {
            throw new Error(`Error fetching standings: ${response.statusText}`);
        }
        const standings = await response.json();

        if (standings.result && Array.isArray(standings.result.rows)) {
            const usersCol = db.collection('users');
            for (const row of standings.result.rows) {
                const member = row.party.members?.[0]
                if (!member?.handle) continue

                const handle = member.handle
                // Firestore query for a document where "handle" equals the CF handle
                const snapshot = await usersCol.where('handle', '==', handle).limit(1).get()
                if (!snapshot.empty) {
                    const userDoc = snapshot.docs[0];
                    const userRef = userDoc.ref;
                    const userData = userDoc.data();
                    const practiceTags = new Set(userData.practiceTags || []);

                    // total participants in this contest
                    const totalParticipants = standings.result.rows.length;

                    // precompute how many solved each problem
                    const solveCounts = standings.result.rows.reduce((counts, r) => {
                        r.problemResults.forEach((pr, i) => {
                            if (pr.points > 0) counts[i] = (counts[i] || 0) + 1;
                        });
                        return counts;
                    }, {});

                    // go through each problem for this user
                    standings.result.problems.forEach((problem, i) => {
                        const pr = row.problemResults[i];
                        const solved = pr.points > 0;
                        const failed = pr.failedAttemptCount > 0;
                        const solveCount = solveCounts[i] || 0;

                        if (failed || (!solved && solveCount <= 0.1 * totalParticipants)) {
                            (problem.tags || []).forEach(tag => practiceTags.add(tag));
                        }
                    });

                    // update the user's practiceTags field
                    await userRef.update({
                        practiceTags: Array.from(practiceTags)
                    });
                } 
            }
        }
    } catch (error) {
        console.error(`Error processing contest standings for ${contestId}:`, error);
    }
}

module.exports = async (req, res) => {
    try{
        //Fetch list of contests and take last 5 (FINISHED) ones
        const response = await fetch('https://codeforces.com/api/contest.list?gym=false');
        if (!response.ok) {
            throw new Error(`Error fetching contests: ${response.statusText}`);
        }
        const contests = await response.json();
        const finishedContests = contests.result
            .filter(c => c.phase === 'FINISHED')
            .sort((a, b) => b.startTimeSeconds - a.startTimeSeconds)
            .slice(0, 5);
        
        // Process each contest's standings
        for (const contest of finishedContests) {
            await processContestStandings(contest.id);
        }

        res.status(200).send('Practice tags updated for last 5 finished contests');
    } catch (error) {
        console.error('Error fetching contests or processing standings:', error);
        res.status(500).send('Internal server error');
    }
};