const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');

// POST /submit - User submits a booking application
router.post('/submit', async (req, res) => {
    try {
        const { userId, hostelId } = req.body;

        // Check if user has already booked this hostel
        const existingBooking = await Booking.findOne({ userId, hostelId });
        if (existingBooking) {
            return res.status(400).json({ message: "You have already applied for this hostel" });
        }

        const booking = new Booking(req.body);
        await booking.save();
        res.status(201).json({ message: "Booking application submitted successfully", booking });
    } catch (err) {
        console.error("SUBMIT BOOKING ERROR:", err);
        if (err.name === 'ValidationError') {
            console.error("Mongoose Validation Details:", err.errors);
        }
        res.status(500).json({ 
            message: "Server error during booking submission", 
            error: err.message,
            details: err.errors
        });
    }
});

// GET /admin/all - Admin fetches all bookings, sorted by date
router.get('/admin/all', async (req, res) => {
    try {
        const bookings = await Booking.find().sort({ createdAt: 1 });
        res.json(bookings);
    } catch (err) {
        console.error("GET ALL BOOKINGS ERROR:", err);
        res.status(500).json({ message: "Error fetching bookings" });
    }
});

// PUT /admin/:id/status - Admin updates booking status
router.put('/admin/:id/status', async (req, res) => {
    try {
        const { status, waitlistRank } = req.body;
        const booking = await Booking.findById(req.params.id);
        if (!booking) return res.status(404).json({ message: "Booking not found" });

        if (status) booking.status = status;
        if (waitlistRank !== undefined) booking.waitlistRank = waitlistRank;

        await booking.save();
        res.json({ message: `Booking status updated to ${status}`, booking });
    } catch (err) {
        console.error("UPDATE STATUS ERROR:", err);
        res.status(500).json({ message: "Error updating booking status" });
    }
});

// GET /user/:userId - User fetches their own bookings
router.get('/user/:userId', async (req, res) => {
    try {
        const bookings = await Booking.find({ userId: req.params.userId }).sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        console.error("GET USER BOOKINGS ERROR:", err);
        res.status(500).json({ message: "Error fetching user bookings" });
    }
});

// GET /owner/:ownerId - Owner fetches approved bookings for their hostels
router.get('/owner/:ownerId', async (req, res) => {
    try {
        const bookings = await Booking.find({ 
            ownerId: req.params.ownerId,
            status: 'approved'
        }).sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        console.error("GET OWNER BOOKINGS ERROR:", err);
        res.status(500).json({ message: "Error fetching owner bookings" });
    }
});

// PUT /owner/:id/appointment - Owner sets appointment date/time
router.put('/owner/:id/appointment', async (req, res) => {
    try {
        const { date, time } = req.body;
        const booking = await Booking.findById(req.params.id);
        if (!booking) return res.status(404).json({ message: "Booking not found" });

        booking.appointmentDate = date;
        booking.appointmentTime = time;

        await booking.save();
        res.json({ message: "Appointment set successfully", booking });
    } catch (err) {
        console.error("SET APPOINTMENT ERROR:", err);
        res.status(500).json({ message: "Error setting appointment" });
    }
});

module.exports = router;
