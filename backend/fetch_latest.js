const mongoose = require('mongoose');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const Hostel = require('./models/Hostel');

dotenv.config();
connectDB();

async function run() {
  const h = await Hostel.findOne().sort({createdAt:-1});
  console.log(JSON.stringify(h, null, 2));
  process.exit(0);
}
run();
