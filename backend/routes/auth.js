const express = require("express");
const bcrypt = require("bcryptjs");
const User = require("../models/user");

const router = express.Router();

/* CHECK IF ADMIN EXISTS */
router.get("/admin-exists", async (req, res) => {
  try {
    const admin = await User.findOne({ role: "admin" });
    res.json({ hasAdmin: !!admin });
  } catch (err) {
    console.error("ADMIN CHECK ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
});

/* REGISTER */
router.post("/register", async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({ message: "All fields required" });
    }

    if (!["admin", "user"].includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }

    if (role === "admin") {
      const existingAdmin = await User.findOne({ role: "admin" });
      if (existingAdmin) {
        return res.status(400).json({ message: "An admin account already exists. Only one admin is allowed." });
      }
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashed = await bcrypt.hash(password, 10);

    const user = new User({
      name,
      email,
      password: hashed,
      role,
    });

    await user.save();

    res.json({ message: "Registered successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Registration failed" });
  }
});

/* LOGIN */
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "Invalid email or password" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid email or password" });
    }

    res.json({
      role: user.role,
      id: user._id,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});

/* ================= GET PROFILE ================= */
router.get("/me/:id", async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    
    res.json(user);
  } catch (err) {
    console.error("GET PROFILE ERROR:", err);
    res.status(500).json({ message: "Error fetching profile" });
  }
});

/* ================= UPDATE PROFILE ================= */
router.put("/update-profile/:id", async (req, res) => {
  try {
    const { name, phone, email } = req.body;
    
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });
    
    if (email !== undefined && email !== user.email) {
      const existingUser = await User.findOne({ email });
      if (existingUser && existingUser._id.toString() !== req.params.id) {
          return res.status(400).json({ message: "Email is already in use by another account" });
      }
      user.email = email;
    }

    if (name !== undefined) user.name = name;
    if (phone !== undefined) user.phone = phone;
    
    await user.save();
    
    // Return updated user without password
    const updatedUser = user.toObject();
    delete updatedUser.password;
    
    res.json({ message: "Profile updated successfully", user: updatedUser });
  } catch (err) {
    console.error("UPDATE PROFILE ERROR:", err);
    res.status(500).json({ message: "Error updating profile" });
  }
});

/* ================= CHANGE PASSWORD ================= */
router.post("/change-password/:id", async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: "Both passwords are required" });
    }
    
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });
    
    // Check old password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Incorrect current password" });
    }
    
    // Hash new password
    const hashedNew = await bcrypt.hash(newPassword, 10);
    user.password = hashedNew;
    
    await user.save();
    res.json({ message: "Password changed successfully" });
  } catch (err) {
    console.error("CHANGE PASSWORD ERROR:", err);
    res.status(500).json({ message: "Error changing password" });
  }
});

module.exports = router;
