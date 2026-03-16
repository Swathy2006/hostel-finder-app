const mongoose = require('mongoose');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const Hostel = require('./models/Hostel');

dotenv.config();
connectDB();

async function testInsert() {
  try {
    const testHostel = new Hostel({
      name: "Debug Granular Hostel",
      address: "123 Test St",
      ownerName: "Debugger",
      contactNo: "9000000000",
      rentSingle: 1000,
      rentShared: 500,
      vacancy: 10,
      owner: new mongoose.Types.ObjectId(), // Fake owner
      district: "Test District",
      city: "Test City",
      isApproved: true,
      location: { type: "Point", coordinates: [76, 10] },
      totalRooms: 15,
      totalMembers: 30,
      vacantRooms: 5,
      rooms: [
        { type: "single", sharingCount: 1, rent: 1000, totalRooms: 5, vacancy: 2 },
        { type: "shared", sharingCount: 2, rent: 500, totalRooms: 10, vacancy: 8 }
      ]
    });

    console.log("Attempting to save:");
    console.log(JSON.stringify(testHostel, null, 2));

    const saved = await testHostel.save();
    console.log("\nSaved Document received back from MongoDB:");
    console.log(JSON.stringify(saved, null, 2));

  } catch(e) {
    console.error(e);
  } finally {
    process.exit();
  }
}

testInsert();
