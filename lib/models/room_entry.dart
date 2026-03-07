import 'package:flutter/widgets.dart';

/// Used by both create/edit hostel screens to represent a room type entry.
class RoomEntry {
  String type;
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController vacancyCtrl = TextEditingController();

  RoomEntry({this.type = 'single'});
}
