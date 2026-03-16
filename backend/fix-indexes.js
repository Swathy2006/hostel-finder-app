const mongoose = require("mongoose");
const dotenv = require("dotenv");

dotenv.config();

async function fixIndexes() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || "mongodb://localhost:27017/hostel_db");
    console.log("Connected to MongoDB");

    // Drop the problematic index
    const result = await mongoose.connection.collection("hostels").dropIndex("admin_1").catch(err => {
      console.log("Index admin_1 doesn't exist or already dropped:", err.message);
      return null;
    });

    if (result) {
      console.log("Successfully dropped admin_1 index");
    }

    // List all remaining indexes
    const indexes = await mongoose.connection.collection("hostels").getIndexes();
    console.log("Remaining indexes:", indexes);

    await mongoose.connection.close();
    console.log("Done! You can now create hostels.");
  } catch (err) {
    console.error("Error fixing indexes:", err);
    process.exit(1);
  }
}

fixIndexes();
