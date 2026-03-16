const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  hostelId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Hostel',
    required: true
  },
  hostelName: {
    type: String,
    required: true
  },
  ownerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  name: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true
  },
  phone: {
    type: String,
    required: true
  },
  aadhaar: {
    type: String,
    required: true
  },
  duration: {
    type: String, // e.g., "3 Months", "2 Weeks", "10 Days"
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'waitlisted'],
    default: 'pending'
  },
  waitlistRank: {
    type: Number,
    default: 0
  },
  appointmentDate: {
    type: String,
    default: ''
  },
  appointmentTime: {
    type: String,
    default: ''
  }
}, { timestamps: true });

module.exports = mongoose.model('Booking', BookingSchema);
