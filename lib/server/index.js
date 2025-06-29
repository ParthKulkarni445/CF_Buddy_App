// index.js
const express = require("express");
require("dotenv").config();

// Import Firestore from the separate file
const { db } = require("./firebase");
const authRouter = require("./auth");
console.log("Connected to Firestore");
const clubRouter = require('./club-functions');

const PORT = process.env.PORT || 3000;

const app = express();
app.use(express.json());
app.use(clubRouter);

// Mount your routes
app.use(authRouter);

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server is running on port ${PORT}`);
});
