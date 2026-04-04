import 'dart:convert';

import 'package:medicare/helpers/services/json_decoder.dart';
import 'package:medicare/model/identifier_model.dart';
import 'package:flutter/services.dart';

class AppointmentListModel extends IdentifierModel {
  final String name, consultingDoctor, treatment, mobile, email;
  final DateTime date, time;

  AppointmentListModel(super.id, this.name, this.consultingDoctor, this.treatment, this.mobile, this.email, this.date, this.time);

  static AppointmentListModel fromJSON(Map<String, dynamic> json) {
    JSONDecoder jsonDecoder = JSONDecoder(json);

    String name = jsonDecoder.getString('name');
    String consultingDoctor = jsonDecoder.getString('consulting_doctor');
    String treatment = jsonDecoder.getString('treatment');
    String mobile = jsonDecoder.getString('mobile');
    String email = jsonDecoder.getString('email');
    DateTime date = jsonDecoder.getDateTime('date');
    DateTime time = jsonDecoder.getDateTime('time');

    return AppointmentListModel(jsonDecoder.getId, name, consultingDoctor, treatment, mobile, email, date, time);
  }

  static List<AppointmentListModel> listFromJSON(List<dynamic> list) {
    return list.map((e) => AppointmentListModel.fromJSON(e)).toList();
  }

  static List<AppointmentListModel>? _dummyList;

  static Future<List<AppointmentListModel>> get dummyList async {
    if (_dummyList == null) {
      dynamic data = json.decode(await getData());
      _dummyList = listFromJSON(data);
    }
    return _dummyList!;
  }

  static Future<String> getData() async {
    return await rootBundle.loadString('assets/data/appointment_list.json');
  }
}
