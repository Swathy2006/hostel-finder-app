const mongoose = require("mongoose");
const dotenv = require("dotenv");

dotenv.config();

mongoose.connect(process.env.MONGO_URI)
.then(async () => {
  console.log("Connected to MongoDB");
  
  try {
    await mongoose.connection.db.dropCollection("users");
    console.log("Dropped users collection.");
  } catch (err) {
    if (err.code === 26) console.log("Users collection does not exist.");
    else console.error("Error dropping users:", err);
  }

  try {
    await mongoose.connection.db.dropCollection("hostels");
    console.log("Dropped hostels collection.");
  } catch (err) {
    if (err.code === 26) console.log("Hostels collection does not exist.");
    else console.error("Error dropping hostels:", err);
  }

  console.log("Database successfully wiped for Single Admin reset.");
  process.exit(0);
})
.catch((err) => {
  console.error("Error connecting:", err);
  process.exit(1);
});
