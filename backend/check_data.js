const mongoose = require('mongoose');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const Hostel = require('./models/Hostel');
const Application = require('./models/application');

dotenv.config();
connectDB();


async function checkData() {
  console.log("=== CHECKING LATEST HOSTEL ===");
  const latestHostel = await Hostel.findOne().sort({ createdAt: -1 });
  if (latestHostel) {
    console.log(`Name: ${latestHostel.name}`);
    console.log(`Total Rooms: ${latestHostel.totalRooms}`);
    console.log(`Rooms Array:`, JSON.stringify(latestHostel.rooms, null, 2));
    console.log(`Pending Changes:`, JSON.stringify(latestHostel.pendingChanges, null, 2));
  } else {
    console.log("No hostels found.");
  }

  console.log("\n=== CHECKING LATEST APPLICATION ===");
  const latestApp = await Application.findOne().sort({ createdAt: -1 });
  if (latestApp) {
    console.log(`Name: ${latestApp.hostelName}`);
    console.log(`Total Rooms: ${latestApp.totalRooms}`);
    console.log(`Rooms Array:`, JSON.stringify(latestApp.rooms, null, 2));
  } else {
    console.log("No applications found.");
  }

  process.exit();
}

checkData();
