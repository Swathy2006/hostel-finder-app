import 'package:flutter/material.dart';

class RoomEntry {
  String type; // 'single' or 'shared'
  int sharingCount; // 2, 3, 4, 5 if shared
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController vacancyCtrl = TextEditingController();
  final TextEditingController totalRoomsCtrl = TextEditingController();

  RoomEntry({
    this.type = 'single',
    this.sharingCount = 2,
  });

  String get displayName =>
      type == 'single' ? 'Single' : '$sharingCount Shared';
}
