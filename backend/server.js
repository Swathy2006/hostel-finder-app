const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const connectDB = require("./config/db");

dotenv.config();
connectDB();

const app = express();

app.use(cors());
app.use(express.json());

const authRoutes = require("./routes/auth");
const hostelRoutes = require("./routes/hostel");
const applicationRoutes = require("./routes/application");
const bookingRoutes = require("./routes/booking");

app.use("/api/auth", authRoutes);
app.use("/api/hostels", hostelRoutes);
app.use("/api/applications", applicationRoutes);
app.use("/api/bookings", bookingRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
