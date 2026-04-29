import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ShiftType { morning, afternoon, night, custom }

ShiftType _typeFromString(String? v) {
  switch (v) {
    case 'morning':
      return ShiftType.morning;
    case 'afternoon':
      return ShiftType.afternoon;
    case 'night':
      return ShiftType.night;
    default:
      return ShiftType.custom;
  }
}

extension ShiftTypeX on ShiftType {
  String get label {
    switch (this) {
      case ShiftType.morning:
        return 'Morning';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.custom:
        return 'Custom';
    }
  }

  String get defaultStart {
    switch (this) {
      case ShiftType.morning:
        return '06:00';
      case ShiftType.afternoon:
        return '14:00';
      case ShiftType.night:
        return '22:00';
      case ShiftType.custom:
        return '08:00';
    }
  }

  String get defaultEnd {
    switch (this) {
      case ShiftType.morning:
        return '14:00';
      case ShiftType.afternoon:
        return '22:00';
      case ShiftType.night:
        return '06:00';
      case ShiftType.custom:
        return '16:00';
    }
  }

  Color get color {
    switch (this) {
      case ShiftType.morning:
        return Colors.amber.shade700;
      case ShiftType.afternoon:
        return Colors.blue.shade600;
      case ShiftType.night:
        return Colors.deepPurple.shade400;
      case ShiftType.custom:
        return Colors.teal.shade500;
    }
  }

  Color get bgColor {
    switch (this) {
      case ShiftType.morning:
        return Colors.amber.shade50;
      case ShiftType.afternoon:
        return Colors.blue.shade50;
      case ShiftType.night:
        return Colors.deepPurple.shade50;
      case ShiftType.custom:
        return Colors.teal.shade50;
    }
  }
}

class ShiftModel {
  final String id;
  final String staffId;
  final String staffName;
  final String staffRole;
  final DateTime date;
  final ShiftType type;
  final String startTime;
  final String endTime;
  final String? notes;
  final String hospitalId;
  final String createdBy;
  final DateTime createdAt;

  const ShiftModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.date,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.hospitalId,
    required this.createdBy,
    required this.createdAt,
  });

  factory ShiftModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return ShiftModel(
      id: doc.id,
      staffId: d['staffId'] as String? ?? '',
      staffName: d['staffName'] as String? ?? '',
      staffRole: d['staffRole'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? now,
      type: _typeFromString(d['type'] as String?),
      startTime: d['startTime'] as String? ?? '08:00',
      endTime: d['endTime'] as String? ?? '16:00',
      notes: d['notes'] as String?,
      hospitalId: d['hospitalId'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
    );
  }
}
