import 'package:flutter/material.dart';

class RoomEntry {
  String type; // 'single' or 'shared'
  final TextEditingController sharingCountCtrl = TextEditingController(text: "2");
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController vacancyCtrl = TextEditingController();
  final TextEditingController totalRoomsCtrl = TextEditingController();

  RoomEntry({
    this.type = 'single',
    String sharing = "2",
  }) {
    sharingCountCtrl.text = sharing;
  }

  String get displayName =>
      type == 'single' ? 'Single' : '${sharingCountCtrl.text} Shared';

  Map<String, dynamic> toJson() => {
        'type': type,
        'sharingCount': int.tryParse(sharingCountCtrl.text.trim()) ?? 2,
        'rent': double.tryParse(rentCtrl.text.trim()) ?? 0,
        'totalRooms': int.tryParse(totalRoomsCtrl.text.trim()) ?? 0,
        'vacancy': int.tryParse(vacancyCtrl.text.trim()) ?? 0,
      };
}
