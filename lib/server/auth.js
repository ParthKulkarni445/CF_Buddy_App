const express = require("express");
const bcryptjs = require("bcryptjs");
const { db } = require("./firebase");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const authRouter = express.Router();
const auth = require("./tokenverify");
const usersCollection = db.collection("users");

// Temporary storage for verification codes
const verificationCodes = new Map();

// Helper: validate basic email format
function isValidEmail(email) {
  const re = /^\S+@\S+\.\S+$/;
  return re.test(email);
}

// Verify email endpoint
authRouter.post('/api/verify-email', async (req, res) => {
  try {
    const { EMAIL_USER, EMAIL_PASS } = process.env;
    if (!EMAIL_USER || !EMAIL_PASS) {
      console.error('Missing SMTP credentials');
      return res.status(500).json({ success: false, msg: 'The email service is not configured properly. Please contact the developer.' });
    }

    const { email } = req.body;
    if (!email || !isValidEmail(email.trim())) {
      return res.status(400).json({ success: false, msg: 'The email format provided is invalid. Please enter a valid email address.' });
    }
    const cleanEmail = email.trim().toLowerCase();

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    verificationCodes.set(cleanEmail, code);

    const transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: { user: EMAIL_USER, pass: EMAIL_PASS },
    });

    await transporter.sendMail({
      from: EMAIL_USER,
      to: cleanEmail,
      subject: 'Email Verification Code',
      text: `Your verification code is: ${code}`,
    });

    return res.status(200).json({ success: true, msg: 'A verification code has been sent to your email address.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, msg: 'An error occurred while sending the verification code. Please try again later.' });
  }
});

// Validate Auth Code endpoint
authRouter.post('/api/validate-auth-code', async (req, res) => {
  try {
    const { email, verificationCode } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();

    if (!cleanEmail || !isValidEmail(cleanEmail)) {
      return res.status(400).json({ success: false, msg: 'The email format provided is invalid. Please enter a valid email address.' });
    }
    if (!verificationCode) {
      return res.status(400).json({ success: false, msg: 'A verification code is required.' });
    }

    const stored = verificationCodes.get(cleanEmail);
    if (!stored || stored !== verificationCode) {
      return res.status(400).json({ success: false, msg: 'The verification code is invalid. Please enter the correct code.' });
    }

    // Optionally, you can delete the code after successful validation
    verificationCodes.delete(cleanEmail);

    return res.status(200).json({ success: true, msg: 'Verification code validated successfully.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, msg: 'An error occurred while validating the code. Please try again later.' });
  }
});

// Sign Up
authRouter.post("/api/signup", async (req, res) => {
  try {
    const { handle, email} = req.body;

    // Check if user already exists
    const existingUser = await usersCollection.where("email", "==", email).get();
    if (!existingUser.empty) {
      return res.status(400).json({ msg: "A user with the same email address already exists. Please use a different email." });
    }

    const existingHandle = await usersCollection.where("handle", "==", handle).get();
    if (!existingHandle.empty) {
      return res.status(400).json({ msg: "A user with the same handle already exists. Please choose a different handle." });
    }

    // Create new user in Firestore
    const newUserRef = usersCollection.doc();
    await newUserRef.set({
      handle,
      email
    });

    res.json({ id: newUserRef.id, handle, email });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'An error occurred while creating your account. Please try again later.' });
  }
});

// Sign In
authRouter.post("/api/signin", async (req, res) => {
  try {
    const {handle} = req.body;

    // Find user by handle
    const userSnapshot = await usersCollection.where("handle", "==", handle).get();
    if (userSnapshot.empty) {
      return res.status(400).json({ msg: "No user found with the provided handle. Please check and try again." });
    }

    // Get user data
    const userDoc = userSnapshot.docs[0];
    const user = userDoc.data();

    // Generate JWT token
    const token = jwt.sign({ id: userDoc.id }, process.env.JWT_SECRET);
    res.json({ token, id: userDoc.id, handle: user.handle, email: user.email });
  } catch (e) {
    res.status(500).json({ error: 'An error occurred while signing in. Please try again later.' });
  }
});

// Token Validation
authRouter.post("/tokenIsValid", async (req, res) => {
  try {
    const token = req.header("x-auth-token");
    if (!token) return res.json(false);

    const verified = jwt.verify(token, process.env.JWT_SECRET);
    if (!verified) return res.json(false);

    const userRef = usersCollection.doc(verified.id);
    const user = await userRef.get();

    if (!user.exists) return res.json(false);

    res.json(true);
  } catch (e) {
    res.status(500).json({ error: 'An error occurred while validating the token. Please try again later.' });
  }
});

// Get User Data
authRouter.get("/", auth, async (req, res) => {
  try {
    const userRef = usersCollection.doc(req.user);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      return res.status(404).json({ msg: "No user found with the provided ID. Please check and try again." });
    }

    const user = userSnapshot.data();
    res.json({ id: userRef.id, ...user, token: req.token });
  } catch (e) {
    res.status(500).json({ error: 'An error occurred while retrieving user data. Please try again later.' });
  }
});

module.exports = authRouter;