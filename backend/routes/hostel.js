const express = require("express");
const Hostel = require("../models/Hostel");
const User = require("../models/user");

const router = express.Router();

/* ================= CREATE HOSTEL (ADMIN ONLY) ================= */
router.post("/create", async (req, res) => {
  try {
    const {
      name,
      address,
      ownerName,
      contactNo,
      lat,
      lng,
      rentSingle,
      rentShared,
      vacancy,
      facilities,
      images,
      videos,
      ownerId,
      district,
      city,
      applicationId,
      gender,
      totalRooms,
      totalMembers,
      vacantRooms,
      rooms,
    } = req.body;

    let parsedRooms = [];
    try {
      if (rooms) parsedRooms = typeof rooms === 'string' ? JSON.parse(rooms) : rooms;
    } catch (e) {
      console.log("Error parsing rooms:", e);
    }

    let parsedFacilities = [];
    try {
      if (facilities) parsedFacilities = typeof facilities === 'string' ? JSON.parse(facilities) : facilities;
    } catch (e) {
      if (typeof facilities === 'string') parsedFacilities = facilities.split(',');
    }

    console.log("=== CREATE HOSTEL REQUEST ===");
    console.log("Total Rooms:", totalRooms);
    console.log("Total Members:", totalMembers);
    console.log("Vacant Rooms:", vacantRooms);
    console.log("Parsed Rooms array length:", parsedRooms.length);
    console.log("=============================");

    // Validate required fields
    if (!name || !address || !ownerId || !district || !city) {
      return res.status(400).json({ message: "Missing required fields: name, address, ownerId, district, city" });
    }

    // Validate coordinates
    if (lat === undefined || lng === undefined || lat === 0 && lng === 0) {
      return res.status(400).json({ message: "Invalid location coordinates" });
    }

    // Validate admin
    const user = await User.findById(ownerId);
    console.log("USER LOOKUP RESULT:", user);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const isApproved = user.role === "admin";

    const hostel = new Hostel({
      name,
      address,
      ownerName,
      contactNo,
      rentSingle,
      rentShared,
      vacancy,
      facilities: parsedFacilities,
      images: images || [],
      videos: videos || [],
      owner: ownerId,
      district,
      city,
      isApproved,
      gender: gender || "Mixed",
      location: {
        type: "Point",
        coordinates: [Number(lng), Number(lat)],
      },
      totalRooms: Number(totalRooms) || 0,
      totalMembers: Number(totalMembers) || 0,
      vacantRooms: Number(vacantRooms) || 0,
      rooms: parsedRooms,
    });

    console.log("HOSTEL DATA TO SAVE:", hostel);
    await hostel.save();

    // If an applicationId was provided, link them
    if (applicationId) {
      const Application = require("../models/application");
      await Application.findByIdAndUpdate(applicationId, {
        hostelDraftId: hostel._id,
        status: 'publish_request_pending'
      });
    } else if (!isApproved) {
      // Auto-generate Application tracking document for direct user submissions
      const Application = require("../models/application");
      const appDoc = new Application({
        userId: ownerId,
        hostelName: name,
        ownerName: ownerName,
        email: user.email || 'N/A', // Fallback if user object doesn't have email populated or structured differently
        phone: contactNo,
        district: district,
        city: city,
        status: 'publish_request_pending',
        hostelDraftId: hostel._id,
        totalRooms: totalRooms || 0,
        totalMembers: totalMembers || 0,
        vacantRooms: vacantRooms || 0,
        gender: gender || 'Mixed',
        rooms: rooms || []
      });
      await appDoc.save();
    }

    res.json({ message: "Hostel created successfully", hostel });
  } catch (err) {
    console.error("CREATE HOSTEL ERROR:", err);
    res.status(500).json({ message: "Error creating hostel", error: err.message });
  }
});

/* ================= GET ALL APPROVED HOSTELS ================= */
router.get("/", async (req, res) => {
  try {
    const hostels = await Hostel.find({ isApproved: { $ne: false } });
    res.json(hostels);
  } catch (err) {
    console.error("FETCH HOSTELS ERROR:", err);
    res.status(500).json({ message: "Error fetching hostels" });
  }
});

/* ================= GET NEARBY HOSTELS ================= */
router.get("/nearby", async (req, res) => {
  try {
    const { lat, lng, maxDistance = 50000 } = req.query; // Default 50km

    if (!lat || !lng) {
      return res.status(400).json({ message: "lat and lng are required" });
    }

    const hostels = await Hostel.aggregate([
      {
        $geoNear: {
          near: {
            type: "Point",
            coordinates: [parseFloat(lng), parseFloat(lat)],
          },
          distanceField: "distance",
          maxDistance: parseInt(maxDistance),
          spherical: true,
          query: { isApproved: { $ne: false } },
        },
      },
      {
        $addFields: {
          distance: { $divide: ["$distance", 1000] }, // Convert to km
        },
      },
    ]);

    res.json(hostels);
  } catch (err) {
    console.error("FETCH NEARBY HOSTELS ERROR:", err);
    res.status(500).json({ message: "Error fetching nearby hostels" });
  }
});

/* ================= GET HOSTELS BY OWNER ================= */
router.get("/owner/:id", async (req, res) => {
  try {
    const hostels = await Hostel.find({ owner: req.params.id });
    res.json(hostels);
  } catch (err) {
    console.error("FETCH HOSTELS BY OWNER ERROR:", err);
    res.status(500).json({ message: "Error fetching hostels for owner" });
  }
});

/* ================= UPDATE HOSTEL ================= */
router.put("/:id", async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);
    if (!hostel) {
      return res.status(404).json({ message: "Hostel not found" });
    }

    const {
      name,
      address,
      ownerName,
      contactNo,
      lat,
      lng,
      rentSingle,
      rentShared,
      vacancy,
      facilities,
      images,
      videos,
      city,
      totalRooms,
      totalMembers,
      vacantRooms,
      gender,
      rooms,
    } = req.body;

    // optionally check ownerId from token or body
    if (name !== undefined) hostel.name = name;
    if (address !== undefined) hostel.address = address;
    if (ownerName !== undefined) hostel.ownerName = ownerName;
    if (contactNo !== undefined) hostel.contactNo = contactNo;
    if (district !== undefined) hostel.district = district;
    if (city !== undefined) hostel.city = city;
    if (totalRooms !== undefined) hostel.totalRooms = Number(totalRooms) || 0;
    if (totalMembers !== undefined) hostel.totalMembers = Number(totalMembers) || 0;
    if (vacantRooms !== undefined) hostel.vacantRooms = Number(vacantRooms) || 0;
    if (gender !== undefined) hostel.gender = gender;
    if (lat !== undefined && lng !== undefined) {
      hostel.location.coordinates = [Number(lng), Number(lat)];
    }
    if (rentSingle !== undefined) hostel.rentSingle = rentSingle;
    if (rentShared !== undefined) hostel.rentShared = rentShared;
    if (vacancy !== undefined) hostel.vacancy = vacancy;
    if (facilities !== undefined) {
      try {
        hostel.facilities = typeof facilities === 'string' ? JSON.parse(facilities) : facilities;
      } catch (e) {
        if (typeof facilities === 'string') hostel.facilities = facilities.split(',');
      }
    }
    if (images !== undefined) hostel.images = images;
    if (videos !== undefined) hostel.videos = videos;
    if (rooms !== undefined) {
      try {
        hostel.rooms = typeof rooms === 'string' ? JSON.parse(rooms) : rooms;
      } catch(e) {
        console.log("Error parsing edit rooms", e);
      }
    }

    await hostel.save();
    res.json({ message: "Hostel updated", hostel });
  } catch (err) {
    console.error("UPDATE HOSTEL ERROR:", err);
    res.status(500).json({ message: "Error updating hostel" });
  }
});

/* ================= PUBLISH REQUESTS (ADMIN ONLY) ================= */
router.get("/publish-requests", async (req, res) => {
  try {
    const requests = await Hostel.find({ isApproved: false })
      .populate("owner", "name email role") // Optional: to get owner info
      .sort({ createdAt: -1 });
    res.json(requests);
  } catch (err) {
    console.error("FETCH PUBLISH REQUESTS ERROR:", err);
    res.status(500).json({ message: "Error fetching publish requests" });
  }
});

/* ================= APPROVE PUBLISH REQUEST (ADMIN ONLY) ================= */
router.put("/approve/:id", async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);
    if (!hostel) {
      return res.status(404).json({ message: "Hostel not found" });
    }
    
    hostel.isApproved = true;
    await hostel.save();
    
    // Attempt to update the linked application (if exists) so the user knows it's published
    const Application = require("../models/application");
    await Application.findOneAndUpdate(
      { hostelDraftId: hostel._id },
      { status: 'published' }
    );

    res.json({ message: "Hostel approved and published", hostel });
  } catch (err) {
    console.error("APPROVE HOSTEL ERROR:", err);
    res.status(500).json({ message: "Error approving hostel" });
  }
});

/* ADMIN: Reject Hostel Publish Request */
router.put('/reject/:id', async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);
    if (!hostel) {
      return res.status(404).json({ message: "Hostel not found" });
    }

    const { adminMessage } = req.body;

    // Attempt to update the linked application
    const Application = require("../models/application");
    await Application.findOneAndUpdate(
      { hostelDraftId: hostel._id },
      { status: 'rejected', adminMessage: adminMessage || '' }
    );

    res.json({ message: "Hostel publish request rejected/reviewed" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

/* ================= SUBMIT EDIT REQUEST (OWNER) ================= */
router.put("/submit-change/:id", async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);
    if (!hostel) {
      return res.status(404).json({ message: "Hostel not found" });
    }

    let pending = { ...req.body };
    if (pending.totalRooms !== undefined) pending.totalRooms = Number(pending.totalRooms) || 0;
    if (pending.totalMembers !== undefined) pending.totalMembers = Number(pending.totalMembers) || 0;
    if (pending.vacantRooms !== undefined) pending.vacantRooms = Number(pending.vacantRooms) || 0;
    if (pending.lng !== undefined) pending.lng = Number(pending.lng);
    if (pending.lat !== undefined) pending.lat = Number(pending.lat);
    
    if (pending.rooms !== undefined && typeof pending.rooms === 'string') {
      try { pending.rooms = JSON.parse(pending.rooms); } catch(e) { console.log("error parse", e); }
    }
    if (pending.facilities !== undefined && typeof pending.facilities === 'string') {
      try { pending.facilities = JSON.parse(pending.facilities); } catch(e) { pending.facilities = pending.facilities.split(','); }
    }

    // Store the incoming body as pendingChanges
    hostel.pendingChanges = pending;
    hostel.hasPendingEdits = true;
    
    await hostel.save();
    res.json({ message: "Edit request submitted for approval", hostel });
  } catch (err) {
    console.error("SUBMIT EDIT ERROR:", err);
    res.status(500).json({ message: "Error submitting edit request" });
  }
});

/* ================= GET ALL EDIT REQUESTS (ADMIN) ================= */
router.get("/edit-requests", async (req, res) => {
  try {
    const hostels = await Hostel.find({ hasPendingEdits: true })
      .populate("owner", "name email");
    res.json(hostels);
  } catch (err) {
    console.error("FETCH EDIT REQUESTS ERROR:", err);
    res.status(500).json({ message: "Error fetching edit requests" });
  }
});

/* ================= APPROVE EDIT REQUEST (ADMIN) ================= */
router.put("/approve-edit/:id", async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);
    if (!hostel || !hostel.pendingChanges) {
      return res.status(404).json({ message: "Hostel or pending changes not found" });
    }

    const changes = hostel.pendingChanges;

    // Apply changes to the main hostel object
    if (changes.name !== undefined) hostel.name = changes.name;
    if (changes.address !== undefined) hostel.address = changes.address;
    if (changes.ownerName !== undefined) hostel.ownerName = changes.ownerName;
    if (changes.contactNo !== undefined) hostel.contactNo = changes.contactNo;
    if (changes.district !== undefined) hostel.district = changes.district;
    if (changes.city !== undefined) hostel.city = changes.city;
    if (changes.rentSingle !== undefined) hostel.rentSingle = changes.rentSingle;
    if (changes.rentShared !== undefined) hostel.rentShared = changes.rentShared;
    if (changes.vacancy !== undefined) hostel.vacancy = changes.vacancy;
    if (changes.facilities !== undefined) {
      if (typeof changes.facilities === 'string') {
        try { hostel.facilities = JSON.parse(changes.facilities); } catch(e) { hostel.facilities = changes.facilities.split(','); }
      } else {
        hostel.facilities = changes.facilities;
      }
    }
    if (changes.images !== undefined) hostel.images = changes.images;
    if (changes.videos !== undefined) hostel.videos = changes.videos;
    if (changes.lat !== undefined && changes.lng !== undefined) {
      hostel.location.coordinates = [changes.lng, changes.lat];
    }
    if (changes.gender !== undefined) hostel.gender = changes.gender;
    if (changes.totalRooms !== undefined) hostel.totalRooms = Number(changes.totalRooms) || 0;
    if (changes.totalMembers !== undefined) hostel.totalMembers = Number(changes.totalMembers) || 0;
    if (changes.vacantRooms !== undefined) hostel.vacantRooms = Number(changes.vacantRooms) || 0;
    
    if (changes.rooms !== undefined) {
      if (typeof changes.rooms === 'string') {
        try { hostel.rooms = JSON.parse(changes.rooms); } catch(e) { }
      } else {
        hostel.rooms = changes.rooms;
      }
    }

    // Clear pending state
    hostel.pendingChanges = null;
    hostel.hasPendingEdits = false;

    await hostel.save();
    res.json({ message: "Changes approved and applied", hostel });
  } catch (err) {
    console.error("APPROVE EDIT ERROR:", err);
    res.status(500).json({ message: "Error approving changes" });
  }
});

/* ================= REJECT EDIT REQUEST (ADMIN) ================= */
router.put("/reject-edit/:id", async (req, res) => {
  try {
    const hostel = await Hostel.findById(req.params.id);
    if (!hostel) {
      return res.status(404).json({ message: "Hostel not found" });
    }

    hostel.pendingChanges = null;
    hostel.hasPendingEdits = false;

    await hostel.save();
    res.json({ message: "Edit request rejected and cleared" });
  } catch (err) {
    console.error("REJECT EDIT ERROR:", err);
    res.status(500).json({ message: "Error rejecting edit request" });
  }
});

module.exports = router;
