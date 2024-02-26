import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:new_sukoon/screens/chat/chat_screen.dart';
import 'package:new_sukoon/screens/chat_list/chat_list_item.dart';
import 'package:new_sukoon/widgets/blank_content.dart';
import 'package:new_sukoon/widgets/startup_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import '../../cubits/guest/guest_cubit.dart';
import '../../models/user_model.dart';
import '../../utils/laravel_echo/laravel_echo.dart';
import '../../utils/logger.dart';
import '../../utils/onesignal/onesignal.dart';
import '../guest/guest_screen.dart';
import 'package:search_page/search_page.dart';

class OneSignal {
  static OneSignal shared = OneSignal();
  final MethodChannel _channel = const MethodChannel('OneSignal');
  
  Future<bool> userProvidedPrivacyConsent() async {
  var val = await OneSignal.shared._channel.invokeMethod("OneSignal#userProvidedPrivacyConsent");
  return val as bool;
}

Future<bool> requiresUserPrivacyConsent() async {
    var val =
        await _channel.invokeMethod("OneSignal#requiresUserPrivacyConsent");

    return val as bool;
  }

    Future<bool> promptUserForPushNotificationPermission(
      {bool fallbackToSettings = false}) async {
    dynamic result = await _channel.invokeMethod(
        "OneSignal#promptPermission", {'fallback': fallbackToSettings});

    return result as bool? ?? false;
  }
  
  Future<void> consentGranted(bool granted) async {
    await _channel
        .invokeMethod("OneSignal#consentGranted", {'granted': granted});
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static const routeName = "chat-list";

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Future<void> setupOneSignal(int userId) async {
    await initOneSignal();
    registerOneSignalEventListener(
      onOpened: onOpened,
      onReceivedInForeground: onReceivedInForeground,
    );
    promptPolicyPrivacy(userId);
  }

  void onOpened(OSNotificationClickEvent result) {
    vLog('NOTIFICATION OPENED HANDLER CALLED WITH: $result');
    vLog(
        "Opened notification: \n${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}");

    try {
      final data = result.notification.additionalData;
      if (data != null) {
        final chatId = (data['data']['chatId'] as int);
        final chatBloc = context.read<ChatBloc>();
        final selectedChat = chatBloc.state.selectedChat;

        if (chatId != selectedChat?.id) {
          chatBloc.add(ChatNotificationOpened(chatId));
          Navigator.of(context).pushNamed(ChatScreen.routeName);
        }
      }
    } catch (_) {}
  }

  void onReceivedInForeground(OSNotificationWillDisplayEvent event) {
    vLog(
        "Notification received in foreground notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}");
    final chatBloc = context.read<ChatBloc>();
    try {
      final data = event.notification.additionalData;
      final selectedChat = chatBloc.state.selectedChat;

      if (selectedChat != null && data != null) {
        vLog(data);
        final chatId = (data['data']['chatId'] as int);

        if (selectedChat.id == chatId) {
          event.preventDefault();
          //event.preventDefault();
          return;
        }
      }
      chatBloc.add(const ChatStarted());
      event.notification.display();
      //event.notification.display();

      vLog(data);
    } catch (_) {
      event.preventDefault();
      //event.preventDefault();
    }
  }


  /////////////////////////
  ///
  ///
  

  Future<void> promptPolicyPrivacy(int userId) async {
    final oneSignalShared = OneSignal.shared;

    bool userProvidedPrivacyConsent =
        await oneSignalShared.userProvidedPrivacyConsent();

    if (userProvidedPrivacyConsent) {
      sendUserTag(userId);
    } else {
      bool requiresConsent = await oneSignalShared.requiresUserPrivacyConsent();

      if (requiresConsent) {
        final accepted =
            await oneSignalShared.promptUserForPushNotificationPermission();
        if (accepted) {
          await oneSignalShared.consentGranted(true);
          sendUserTag(userId);
        }
      } else {
        sendUserTag(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final authBloc = context.read<AuthBloc>();
    final currentUser = authBloc.state.user!;
    final chatBloc = context.read<ChatBloc>();
    final userBloc = context.read<UserBloc>();
    

    return StartUpContainer(
      onInit: () async {
        chatBloc.add(const ChatStarted());
        userBloc.add(const UserStarted());

        LaravelEcho.init(token: authBloc.state.token!);
        setupOneSignal(authBloc.state.user!.id);
      },
      onDisposed: () {
        LaravelEcho.instance.disconnect();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ChatList"),
              Text(
                "User Id : ${currentUser.username}",
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (!state.isAuthenticated) {
                  deleteUserTag();
                  Navigator.of(context)
                      .pushReplacementNamed(GuestScreen.routeName);
                }
              },
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    context.read<GuestCubit>().signOut();
                  },
                  icon: const Icon(Icons.logout),
                );
              },
            )
          ],
        ),
        
        body: RefreshIndicator(
        backgroundColor: Color(0xFFE4F2FA), // Use light blue color for refresh indicator
        color: Color(0xFF252983), // Use dark blue color for refresh indicator
        onRefresh: () async {
          chatBloc.add(const ChatStarted());
          userBloc.add(const UserStarted());
        },
          child: BlocConsumer<ChatBloc, ChatState>(
            listener: (_, __) {},
            builder: (context, state) {
              if (state.chats.isEmpty) {
                return const BlankContent(
                  content: "No chat available",
                  icon: Icons.chat_rounded,
                );
              }

              return ListView.separated(
                itemBuilder: (context, index) {
                  final item = state.chats[index];

                  return ChatListItem(
                    key: ValueKey(item.id),
                    item: item,
                    currentUser: currentUser,
                    onPressed: (chat) {
                      chatBloc.add(ChatSelected(chat));
                      Navigator.of(context).pushNamed(ChatScreen.routeName);
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(
                  height: 1.5,
                  color: Colors.grey,
                ),
                itemCount: state.chats.length,
              );
            },
          ),
        ),
        floatingActionButton:
            BlocSelector<UserBloc, UserState, List<UserEntity>>(
          selector: (state) {
            return state.map(
              initial: (_) => [],
              loaded: (state) => state.users,
            );
          },
          builder: (context, state) {
            return FloatingActionButton(
              onPressed: () => _showSearch(context, state),
              child: const Icon(Icons.search, color: Colors.white),
              backgroundColor: Color(0xFF252983),
            );
          },
        ),
      ),
    );
  }

  void _showSearch(BuildContext context, List<UserEntity> users) {
    showSearch(
      context: context,
      delegate: SearchPage<UserEntity>(
        items: users,
        searchLabel: 'Search people',
        suggestion: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.search,
                size: 25.0,
                color: Colors.grey,
              ),
              Text(
                'Search users by username',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        failure: const Center(
          child: Text(
            'No person found :(',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
        filter: (user) => [
          user.email,
        ],
        builder: (user) => ListTile(
          leading: const Icon(Icons.account_circle, size: 50.0),
          title: Text(user.username),
          subtitle: Text(user.email),
          
          onTap: () {
            /// selected user
            context.read<ChatBloc>().add(UserSelected(user));

            /// push to chat screen
            Navigator.of(context).pushNamed(ChatScreen.routeName);
          },
        ),
      ),
    );
  }
}