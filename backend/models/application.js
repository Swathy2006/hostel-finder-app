const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  hostelName: {
    type: String,
    required: true
  },
  ownerName: {
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
  district: {
    type: String,
    required: true
  },
  city: {
    type: String,
    required: true
  },
  totalRooms: { type: Number, default: 0 },
  totalMembers: { type: Number, default: 0 },
  vacantRooms: { type: Number, default: 0 },
  gender: { type: String, default: 'Mixed' },
  rooms: [
    {
      type: { type: String }, 
      sharingCount: { type: Number },
      rent: { type: Number },
      totalRooms: { type: Number },
      vacancy: { type: Number },
    },
  ],
  status: {
    type: String,
    enum: ['pending', 'reviewed', 'approved', 'rejected', 'publish_request_pending', 'published'],
    default: 'pending'
  },
  hostelDraftId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Hostel'
  },
  adminMessage: {
    type: String,
    default: ''
  }
}, { timestamps: true });

module.exports = mongoose.model('Application', applicationSchema);
