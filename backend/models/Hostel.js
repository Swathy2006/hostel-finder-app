const mongoose = require("mongoose");

const hostelSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    address: { type: String, required: true },
    ownerName: { type: String, required: true },
    contactNo: { type: String, required: true },

    district: { type: String, required: true },
    city: { type: String, required: true },

    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [lng, lat]
        required: true,
      },
    },

    rentSingle: { type: Number },
    rentShared: { type: Number },
    gender: {
      type: String,
      enum: ["Boys", "Girls", "Mixed"],
      default: "Mixed",
    },
    totalRooms: { type: Number, default: 0 },
    totalMembers: { type: Number, default: 0 },
    vacancy: { type: Number, default: 0 },
    vacantRooms: { type: Number, default: 0 },

    rooms: [
      {
        type: { type: String }, // 'single' or 'shared'
        sharingCount: { type: Number },
        rent: { type: Number },
        totalRooms: { type: Number },
        vacancy: { type: Number },
      },
    ],

    facilities: [{ type: String }],

    images: [{ type: String }],
    videos: [{ type: String }],

    isApproved: { type: Boolean, default: false },

    pendingChanges: { type: Object, default: null },
    hasPendingEdits: { type: Boolean, default: false },

    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true }
);

hostelSchema.index({ location: "2dsphere" });

module.exports = mongoose.model("Hostel", hostelSchema);
