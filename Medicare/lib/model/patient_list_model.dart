import 'dart:convert';

import 'package:medicare/helpers/services/json_decoder.dart';
import 'package:medicare/model/identifier_model.dart';
import 'package:flutter/services.dart';

class PatientListModel extends IdentifierModel {
  final String name, gender, mobileNumber, bloodGroup, address, status;
  final int age;
  final DateTime birthDate;

  PatientListModel(super.id, this.name, this.gender, this.mobileNumber, this.bloodGroup, this.address, this.status, this.age, this.birthDate);

  static PatientListModel fromJSON(Map<String, dynamic> json) {
    JSONDecoder jsonDecoder = JSONDecoder(json);

    String name = jsonDecoder.getString('name');
    String gender = jsonDecoder.getString('gender');
    String mobileNumber = jsonDecoder.getString('mobile_number');
    String bloodGroup = jsonDecoder.getString('blood_group');
    String address = jsonDecoder.getString('address');
    String status = jsonDecoder.getString('status');
    int age = jsonDecoder.getInt('age');
    DateTime birthDate = jsonDecoder.getDateTime('birth_date');

    return PatientListModel(jsonDecoder.getId, name, gender, mobileNumber, bloodGroup, address, status, age, birthDate);
  }

  static List<PatientListModel> listFromJSON(List<dynamic> list) {
    return list.map((e) => PatientListModel.fromJSON(e)).toList();
  }

  static List<PatientListModel>? _dummyList;

  static Future<List<PatientListModel>> get dummyList async {
    if (_dummyList == null) {
      dynamic data = json.decode(await getData());
      _dummyList = listFromJSON(data);
    }
    return _dummyList!;
  }

  static Future<String> getData() async {
    return await rootBundle.loadString('assets/data/patient_list.json');
  }
}
