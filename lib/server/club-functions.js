const express = require("express");
const { db } = require("./firebase");
const auth = require("./tokenverify");
const clubRouter = express.Router();
const clubsCollection = db.collection("clubs");
const admin = require("firebase-admin");

// Create a new club
clubRouter.post("/api/clubs", auth, async (req, res) => {
  try {
    const { name, description, isPublic, bannerUrl, avatarUrl } = req.body;
    const userId = req.user;
    const userDoc = await db.collection('users').doc(userId).get();
    const handle = userDoc.data().handle;

    if (!name || name.trim() === '') {
      return res.status(400).json({ success: false, msg: 'Club name is required' });
    }

    // Check if a club with the same name exists (case-insensitive)
    const existingClubs = await clubsCollection
      .where('name', '==', name)
      .get();
      
    if (!existingClubs.empty) {
      return res.status(400).json({ success: false, msg: 'A club with this name already exists' });
    }

    // Create club document
    const clubRef = clubsCollection.doc();
    const clubId = clubRef.id;
    
    const clubData = {
      id: clubId,
      name,
      description: description || '',
      createdBy: userId,
      createdAt: new Date(),
      bannerUrl: bannerUrl || null,
      avatarUrl: avatarUrl || null,
      members: [userId],
      memberHandles: [handle],
      admins: [userId],
      memberCount: 1,
      isPublic: isPublic !== false,
    };
    
    await clubRef.set(clubData);
    console.log(clubRef.id);
    // Add club to user's clubs
    await db.collection('users').doc(userId).update({
      clubs: admin.firestore.FieldValue.arrayUnion(clubId),
    });
    
    res.status(200).json({ success: true, clubId });
  } catch (error) {
    console.error('Error creating club:', error);
    res.status(500).json({ success: false, msg: 'Failed to create club' });
  }
});

//Delete a club
clubRouter.delete("/api/clubs/:clubId", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const userId = req.user;

    // Check if the club exists
    const clubDoc = await clubsCollection.doc(clubId).get();
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }

    const clubData = clubDoc.data();

    // Check if the user is the creator of the club
    if (clubData.createdBy !== userId) {
      return res.status(403).json({ success: false, msg: 'Only the creator can delete this club' });
    }

    // Delete the club document
    await clubsCollection.doc(clubId).delete();

    // Remove the club from all members
    const memberPromises = clubData.members.map(memberId => 
      db.collection('users').doc(memberId).update({
        clubs: admin.firestore.FieldValue.arrayRemove(clubId),
      })
    );

    await Promise.all(memberPromises);

    res.status(200).json({ success: true, msg: 'Club deleted successfully' });
  } catch (error) {
    console.error('Error deleting club:', error);
    res.status(500).json({ success: false, msg: 'Failed to delete club' });
  }
});

// Search clubs
clubRouter.get("/api/clubs/search", async (req, res) => {
  try {
    const { query } = req.query;
    const snapshot = await clubsCollection.get();
    //console.log(snapshot);
    const clubs = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(club => 
        club.name.toLowerCase().includes(query.toLowerCase())
      );
    //console.log(clubs)
    res.status(200).json({ success: true, clubs });
  } catch (error) {
    console.error('Error searching clubs:', error);
    res.status(500).json({ success: false, msg: 'Failed to search clubs' });
  }
});

// Get club by ID
clubRouter.get("/api/clubs/:clubId", async (req, res) => {
  try {
    const { clubId } = req.params;
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    res.status(200).json({ success: true, club: { id: clubDoc.id, ...clubDoc.data() } });
  } catch (error) {
    console.error('Error getting club:', error);
    res.status(500).json({ success: false, msg: 'Failed to get club' });
  }
});

// Get all clubs
clubRouter.get("/api/clubs", async (req, res) => {
  try {
    const snapshot = await clubsCollection.get();
    const clubs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.status(200).json({ success: true, clubs });
  } catch (error) {
    console.error('Error getting all clubs:', error);
    res.status(500).json({ success: false, msg: 'Failed to get clubs' });
  }
});

// Get user's clubs
clubRouter.get("/api/users/:userId/clubs", auth, async (req, res) => {
  try {
    const userId = req.params.userId.replace(':', ''); // Remove the ':' if present
    
    // First get the user document to get their club IDs
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ success: false, msg: 'User not found' });
    }

    const userData = userDoc.data();
    const userClubIds = userData.clubs || [];

    if (userClubIds.length === 0) {
      return res.status(200).json({ success: true, clubs: [] });
    }

    // Get all clubs in one batch
    const clubPromises = userClubIds.map(clubId => 
      clubsCollection.doc(clubId).get()
    );
    
    const clubDocs = await Promise.all(clubPromises);
    
    const clubs = clubDocs
      .filter(doc => doc.exists) // Filter out any non-existent clubs
      .map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    
    res.status(200).json({ success: true, clubs });
  } catch (error) {
    console.error('Error getting user clubs:', error);
    res.status(500).json({ success: false, msg: 'Failed to get user clubs' });
  }
});

// Join a club
clubRouter.post("/api/clubs/:clubId/join", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const userId = req.user;
    const userDoc = await db.collection('users').doc(userId).get();
    const userHandle = userDoc.data().handle;
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.isPublic) {
      return res.status(400).json({ success: false, msg: 'This club is private' });
    }
    
    if (clubData.members.includes(userId)) {
      return res.status(200).json({ success: true, msg: 'User is already a member of this club' });
    }
    
    await clubsCollection.doc(clubId).update({
      members: admin.firestore.FieldValue.arrayUnion(userId),
      memberHandles: admin.firestore.FieldValue.arrayUnion(userHandle),
      memberCount: admin.firestore.FieldValue.increment(1),
    });
    
    await db.collection('users').doc(userId).update({
      clubs: admin.firestore.FieldValue.arrayUnion(clubId),
    });
    
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error joining club:', error);
    res.status(500).json({ success: false, msg: 'Failed to join club' });
  }
});

// Leave a club
clubRouter.post("/api/clubs/:clubId/leave", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const userId = req.user;
    const userDoc = await db.collection('users').doc(userId).get();
    const userHandle = userDoc.data().handle;
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (clubData.createdBy === userId) {
      return res.status(400).json({ success: false, msg: 'Club creator cannot leave the club' });
    }
    
    await clubsCollection.doc(clubId).update({
      members: admin.firestore.FieldValue.arrayRemove(userId),
      admins: admin.firestore.FieldValue.arrayRemove(userId),
      memberHandles: admin.firestore.FieldValue.arrayRemove(userHandle),
      memberCount: admin.firestore.FieldValue.increment(-1),
    });
    
    await db.collection('users').doc(userId).update({
      clubs: admin.firestore.FieldValue.arrayRemove(clubId),
    });
    
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error leaving club:', error);
    res.status(500).json({ success: false, msg: 'Failed to leave club' });
  }
});

// Add a discussion
clubRouter.post("/api/clubs/:clubId/discussions", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const { title, content, authorName } = req.body;
    const authorId = req.user;
    
    if (!title || title.trim() === '') {
      return res.status(400).json({ success: false, msg: 'Discussion title is required' });
    }
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.members.includes(authorId)) {
      return res.status(400).json({ success: false, msg: 'User is not a member of this club' });
    }
    
    const discussionRef = clubsCollection.doc(clubId).collection('discussions').doc();
    
    const discussionData = {
      id: discussionRef.id,
      clubId,
      title,
      content: content || '',
      authorId,
      authorName,
      createdAt: new Date(),
      commentCount: 0,
      likeCount: 0,
    };
    
    await discussionRef.set(discussionData);
    
    res.status(200).json({ success: true, discussionId: discussionRef.id });
  } catch (error) {
    console.error('Error adding discussion:', error);
    res.status(500).json({ success: false, msg: 'Failed to add discussion' });
  }
});


// Get club discussions
clubRouter.get("/api/clubs/:clubId/discussions", async (req, res) => {
  try {
    const { clubId } = req.params;
    
    const snapshot = await clubsCollection.doc(clubId)
      .collection('discussions')
      .orderBy('createdAt', 'desc')
      .get();
    
    const discussions = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    res.status(200).json({ success: true, discussions });
  } catch (error) {
    console.error('Error getting discussions:', error);
    res.status(500).json({ success: false, msg: 'Failed to get discussions' });
  }
});

// Add a problem
clubRouter.post("/api/clubs/:clubId/problems", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const { title, description, difficulty, points } = req.body;
    const authorId = req.user;
    
    if (!title || title.trim() === '') {
      return res.status(400).json({ success: false, msg: 'Problem title is required' });
    }
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.admins.includes(authorId)) {
      return res.status(400).json({ success: false, msg: 'Only club admins can add problems' });
    }
    
    const problemRef = clubsCollection.doc(clubId).collection('problems').doc();
    
    const problemData = {
      id: problemRef.id,
      clubId,
      title,
      description: description || '',
      difficulty: difficulty || 'medium',
      points: points || 100,
      authorId,
      createdAt: new Date(),
      solvedCount: 0,
    };
    
    await problemRef.set(problemData);
    
    res.status(200).json({ success: true, problemId: problemRef.id });
  } catch (error) {
    console.error('Error adding problem:', error);
    res.status(500).json({ success: false, msg: 'Failed to add problem' });
  }
});

// Get club problems
clubRouter.get("/api/clubs/:clubId/problems", async (req, res) => {
  try {
    const { clubId } = req.params;
    
    const snapshot = await clubsCollection.doc(clubId)
      .collection('problems')
      .orderBy('createdAt', 'desc')
      .get();
    
    const problems = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    res.status(200).json({ success: true, problems });
  } catch (error) {
    console.error('Error getting problems:', error);
    res.status(500).json({ success: false, msg: 'Failed to get problems' });
  }
});

// Get club leaderboard
clubRouter.get("/api/clubs/:clubId/leaderboard", async (req, res) => {
  try {
    const { clubId } = req.params;
    
    const snapshot = await clubsCollection.doc(clubId)
      .collection('leaderboard')
      .orderBy('points', 'desc')
      .get();
    
    const leaderboard = snapshot.docs.map(doc => ({
      userId: doc.id,
      ...doc.data(),
    }));
    
    res.status(200).json({ success: true, leaderboard });
  } catch (error) {
    console.error('Error getting leaderboard:', error);
    res.status(500).json({ success: false, msg: 'Failed to get leaderboard' });
  }
});

module.exports = clubRouter; 