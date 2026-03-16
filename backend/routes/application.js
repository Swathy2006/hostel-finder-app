const express = require('express');
const router = express.Router();
const Application = require('../models/application');

/* USER: Submit Application */
router.post('/submit', async (req, res) => {
  try {
    const { 
      userId, hostelName, ownerName, email, phone, district, city,
      totalRooms, totalMembers, vacantRooms, gender, rooms
    } = req.body;

    if (!userId || !hostelName || !ownerName || !email || !phone || !district || !city) {
      return res.status(400).json({ message: "Basic fields are required" });
    }

    const application = new Application({
      userId,
      hostelName,
      ownerName,
      email,
      phone,
      district,
      city,
      totalRooms: totalRooms || 0,
      totalMembers: totalMembers || 0,
      vacantRooms: vacantRooms || 0,
      gender: gender || 'Mixed',
      rooms: rooms || []
    });

    await application.save();
    res.status(201).json({ message: "Application submitted successfully", application });
  } catch (err) {
    console.error("SUBMIT APPLICATION ERROR:", err);
    console.error(err.stack);
    if (err.name === 'ValidationError') {
        console.error("Mongoose Validation Details:", err.errors);
    }
    res.status(500).json({ 
        message: "Server error during submission", 
        error: err.message,
        details: err.errors
    });
  }
});

/* ADMIN: Get All Applications */
router.get('/all', async (req, res) => {
  try {
    // Sort by latest first
    const apps = await Application.find().sort({ createdAt: -1 });
    res.json(apps);
  } catch (err) {
    console.error("GET ALL APPS ERROR:", err);
    res.status(500).json({ message: "Server error fetching applications" });
  }
});

/* USER: Get My Applications (Notifications) */
router.get('/user/:userId', async (req, res) => {
  try {
    const apps = await Application.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.json(apps);
  } catch (err) {
    console.error("GET USER APPS ERROR:", err);
    res.status(500).json({ message: "Server error fetching user applications" });
  }
});

/* ADMIN: Update Application Status & Message */
router.put('/:id/status', async (req, res) => {
  try {
    const { status, adminMessage } = req.body;
    
    if (!['pending', 'reviewed', 'approved', 'rejected', 'publish_request_pending', 'published'].includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }

    const app = await Application.findById(req.params.id);
    if (!app) {
      return res.status(404).json({ message: "Application not found" });
    }

    app.status = status;
    if (adminMessage !== undefined) {
      app.adminMessage = adminMessage;
    }

    await app.save();
    res.json({ message: "Application updated successfully", application: app });
  } catch (err) {
    console.error("UPDATE APP STATUS ERROR:", err);
    res.status(500).json({ message: "Server error updating application" });
  }
});

/* USER/ADMIN: Get Linked Hostel Draft */
router.get('/hostel-draft/:appId', async (req, res) => {
  try {
    const app = await Application.findById(req.params.appId).populate('hostelDraftId');
    if (!app || !app.hostelDraftId) {
      return res.status(404).json({ message: "No draft found" });
    }
    res.json(app.hostelDraftId);
  } catch (err) {
    console.error("GET DRAFT ERROR:", err);
    res.status(500).json({ message: "Server error fetching draft" });
  }
});

/* USER/ADMIN: Delete Application */
router.delete('/:id', async (req, res) => {
  try {
    const app = await Application.findById(req.params.id);
    if (!app) return res.status(404).json({ message: "Application not found" });

    // If there is a linked draft, we should ideally delete the drafted hostel too
    if (app.hostelDraftId) {
      const Hostel = require('../models/Hostel');
      await Hostel.findByIdAndDelete(app.hostelDraftId);
    }

    await Application.findByIdAndDelete(req.params.id);
    res.json({ message: "Application deleted successfully" });
  } catch (err) {
    console.error("DELETE APP ERROR:", err);
    res.status(500).json({ message: "Server error deleting application" });
  }
});

module.exports = router;
