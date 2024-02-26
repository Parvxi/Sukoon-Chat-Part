// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

import 'user_model.dart';



part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';


@freezed
class ChatMessageEntity with _$ChatMessageEntity {
  const ChatMessageEntity._();

  factory ChatMessageEntity({
    required int id,
    @JsonKey(name: "chat_id") required int chatId,
    @JsonKey(name: "user_id") required int userId,
    required String message,
    @JsonKey(name: "created_at") required String createdAt,
    @JsonKey(name: "updated_at") required String updatedAt,
    required UserEntity user,
  }) = _ChatMessageEntity;

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageEntityFromJson(json);

  ChatMessage get toChatMessage {
    return ChatMessage(
      user: user.toChatUser,
      text: message,
      createdAt: DateTime.parse(createdAt),
    );
  }
}