import 'dart:convert';

import 'package:medicare/helpers/services/json_decoder.dart';
import 'package:medicare/model/identifier_model.dart';
import 'package:flutter/services.dart';

class DoctorModel extends IdentifierModel{
  final String doctorName ,designation,email,mobileNumber,degree;
  final DateTime joiningDate;

  DoctorModel(super.id,this.doctorName, this.designation, this.email, this.mobileNumber, this.degree, this.joiningDate);

  static DoctorModel fromJSON(Map<String,dynamic> json){
    JSONDecoder jsonDecoder = JSONDecoder(json);

    String doctorName = jsonDecoder.getString('doctor_name');
    String designation = jsonDecoder.getString('designation');
    String email = jsonDecoder.getString('email');
    String mobileNumber = jsonDecoder.getString('mobile_number');
    String degree = jsonDecoder.getString('degree');
    DateTime joiningDate = jsonDecoder.getDateTime('joining_date');

    return DoctorModel(jsonDecoder.getId, doctorName, designation, email, mobileNumber, degree, joiningDate);
  }

  static List<DoctorModel> listFromJSON(List<dynamic> list) {
    return list.map((e) => DoctorModel.fromJSON(e)).toList();
  }

  static List<DoctorModel>? _dummyList;

  static Future<List<DoctorModel>> get dummyList async {
    if (_dummyList == null) {
      dynamic data = json.decode(await getData());
      _dummyList = listFromJSON(data);
    }
    return _dummyList!;
  }

  static Future<String> getData() async {
    return await rootBundle.loadString('assets/data/doctor_data.json');
  }
}