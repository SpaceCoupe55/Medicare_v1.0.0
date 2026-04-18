import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsModel {
  final String id;
  final String patientId;
  final String recordedBy;
  final String recordedById;
  final double? systolicBP;
  final double? diastolicBP;
  final double? temperature;
  final double? weight;
  final double? height;
  final int? pulse;
  final int? spO2;
  final int? respiratoryRate;
  final String notes;
  final DateTime recordedAt;

  const VitalsModel({
    required this.id,
    required this.patientId,
    required this.recordedBy,
    required this.recordedById,
    this.systolicBP,
    this.diastolicBP,
    this.temperature,
    this.weight,
    this.height,
    this.pulse,
    this.spO2,
    this.respiratoryRate,
    required this.notes,
    required this.recordedAt,
  });

  factory VitalsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return VitalsModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      recordedBy: d['recordedBy'] as String? ?? '',
      recordedById: d['recordedById'] as String? ?? '',
      systolicBP: (d['systolicBP'] as num?)?.toDouble(),
      diastolicBP: (d['diastolicBP'] as num?)?.toDouble(),
      temperature: (d['temperature'] as num?)?.toDouble(),
      weight: (d['weight'] as num?)?.toDouble(),
      height: (d['height'] as num?)?.toDouble(),
      pulse: (d['pulse'] as num?)?.toInt(),
      spO2: (d['spO2'] as num?)?.toInt(),
      respiratoryRate: (d['respiratoryRate'] as num?)?.toInt(),
      notes: d['notes'] as String? ?? '',
      recordedAt: (d['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'recordedBy': recordedBy,
        'recordedById': recordedById,
        if (systolicBP != null) 'systolicBP': systolicBP,
        if (diastolicBP != null) 'diastolicBP': diastolicBP,
        if (temperature != null) 'temperature': temperature,
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
        if (pulse != null) 'pulse': pulse,
        if (spO2 != null) 'spO2': spO2,
        if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
        'notes': notes,
        'recordedAt': FieldValue.serverTimestamp(),
      };

  String get bpDisplay =>
      systolicBP != null && diastolicBP != null
          ? '${systolicBP!.toInt()}/${diastolicBP!.toInt()}'
          : '—';

  // 'normal' | 'elevated' | 'high' | 'low' | 'unknown'
  String get bpStatus {
    if (systolicBP == null) return 'unknown';
    if (systolicBP! < 90) return 'low';
    if (systolicBP! <= 120) return 'normal';
    if (systolicBP! <= 130) return 'elevated';
    return 'high';
  }

  String get tempStatus {
    if (temperature == null) return 'unknown';
    if (temperature! < 36.1) return 'low';
    if (temperature! <= 37.2) return 'normal';
    if (temperature! <= 38.3) return 'elevated';
    return 'high';
  }

  String get pulseStatus {
    if (pulse == null) return 'unknown';
    if (pulse! < 60) return 'low';
    if (pulse! <= 100) return 'normal';
    return 'high';
  }

  String get spO2Status {
    if (spO2 == null) return 'unknown';
    if (spO2! >= 95) return 'normal';
    if (spO2! >= 90) return 'low';
    return 'critical';
  }

  String get rrStatus {
    if (respiratoryRate == null) return 'unknown';
    if (respiratoryRate! < 12) return 'low';
    if (respiratoryRate! <= 20) return 'normal';
    return 'high';
  }
}
