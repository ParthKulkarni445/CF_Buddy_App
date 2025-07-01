const mongoose = require("mongoose");
const axios = require("axios");

const userSchema = mongoose.Schema({
  handle: {
    required: true,
    type: String,
    trim: true,
    validate: {
      // Mongoose 6+ treats an async fn that returns boolean as a valid async validator
      validator: async function (value) {
        const res = await axios.get(
          `https://codeforces.com/api/user.info?handles=${value}`
        );
        return res.data.status === "OK";
      },
      message: props => `${props.value} is not a valid Codeforces handle!`
    }
  },
  email: {
    required: true,
    type: String,
    trim: true,
    validate: {
      validator: (value) => {
        const re =
          /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
        return value.match(re);
      },
      message: "Please enter a valid email address",
    },
  }
});

const User = mongoose.model("User", userSchema);
module.exports = User;