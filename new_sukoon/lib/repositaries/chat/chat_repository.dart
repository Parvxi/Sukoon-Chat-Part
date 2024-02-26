import 'package:dio/dio.dart';
import '../../models/models.dart';
import '../../models/requests/create_chat_request.dart';
import '../../utils/dio_client/dio_client.dart';
import '../core/endpoints.dart';
import 'base_chat_repository.dart';

class ChatRepository extends BaseChatRepository {
  final Dio _dioClient;

  ChatRepository({
    Dio? dioClient,
  }) : _dioClient = dioClient ?? DioClient().instance;

  @override
  Future<AppResponse<ChatEntity?>> createChat(CreateChatRequest request) async {
    final response =
        await _dioClient.post(Endpoints.createChat, data: request.toJson());

    return AppResponse<ChatEntity?>.fromJson(
      response.data,
      (dynamic json) => response.data['success'] && json != null
          ? ChatEntity.fromJson(json)
          : null,
    );
  }

  @override
  Future<AppResponse<List<ChatEntity>>> getChats() async {
    final response = await _dioClient.get(Endpoints.getChats);

    return AppResponse<List<ChatEntity>>.fromJson(
      response.data,
      (dynamic json) => response.data['success'] && json != null
          ? (json as List<dynamic>).map((e) => ChatEntity.fromJson(e)).toList()
          : [],
    );
  }

  @override
  Future<AppResponse<ChatEntity?>> getSingleChat(int chatId) async {
    final response = await _dioClient.get("${Endpoints.getSingleChat}$chatId");

    return AppResponse<ChatEntity?>.fromJson(
      response.data,
      (dynamic json) => response.data['success'] && json != null
          ? ChatEntity.fromJson(json)
          : null,
    );
  }
}