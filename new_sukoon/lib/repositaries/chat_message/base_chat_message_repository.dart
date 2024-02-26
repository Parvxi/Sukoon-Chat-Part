import '../../models/models.dart';
import '../../models/requests/requests.dart';

abstract class BaseChatMessageRepository {
  Future<AppResponse<List<ChatMessageEntity>>> getChatMessages({
    required int chatId,
    required int page,
  });

  Future<AppResponse<ChatMessageEntity?>> createChatMessage(
    CreateChatMessageRequest request,
    String socketId,
  );
}