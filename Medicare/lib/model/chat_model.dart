import 'dart:convert';

import 'package:medicare/helpers/services/json_decoder.dart';
import 'package:medicare/images.dart';
import 'package:medicare/model/identifier_model.dart';
import 'package:flutter/services.dart';

class ChatModel extends IdentifierModel {
  final String firstName, image, email;

  final List<ChatMessageModel> messages;

  ChatModel(super.id, this.firstName, this.image, this.messages, this.email);

  static ChatModel fromJSON(Map<String, dynamic> json) {
    JSONDecoder decoder = JSONDecoder(json);

    String firstName = decoder.getString('first_name');
    String email = decoder.getString('email');
    String image = Images.randomImage(Images.avatars);

    List<dynamic>? messagesList = decoder.getObjectListOrNull('messages');
    List<ChatMessageModel> messages = [];
    messages = ChatMessageModel.listFromJSON(messagesList ?? []);
  
    return ChatModel(decoder.getId, firstName, image, messages, email);
  }

  static List<ChatModel> listFromJSON(List<dynamic> list) {
    return list.map((e) => ChatModel.fromJSON(e)).toList();
  }

  static List<ChatModel>? _dummyList;

  static Future<List<ChatModel>> get dummyList async {
    if (_dummyList == null) {
      dynamic data = json.decode(await getData());
      _dummyList = listFromJSON(data);
    }

    return _dummyList!;
  }

  static Future<String> getData() async {
    return await rootBundle.loadString('assets/data/chat_data.json');
  }
}

class ChatMessageModel extends IdentifierModel {
  final String message, imageSent;
  final DateTime sendAt;
  final bool fromMe;

  ChatMessageModel(super.id, this.message, this.sendAt, this.fromMe, this.imageSent);

  static ChatMessageModel fromJSON(Map<String, dynamic> json) {
    JSONDecoder decoder = JSONDecoder(json);

    String message = decoder.getString('message');
    String imageSent = Images.randomImage(Images.avatars);
    DateTime sendAt = decoder.getDateTime('send_at');
    bool fromMe = decoder.getBool('from_me');

    return ChatMessageModel(decoder.getId, message, sendAt, fromMe, imageSent);
  }

  static List<ChatMessageModel> listFromJSON(List<dynamic> list) {
    return list.map((e) => ChatMessageModel.fromJSON(e)).toList();
  }
}
