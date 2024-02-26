import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../utils/utils.dart';

const oneSignalAppId = "7e5b066a-45bd-44b1-9f2c-ec86a91ea477";

Future<void> initOneSignal() async {
  OneSignal.initialize(oneSignalAppId);
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Notifications.requestPermission(true);
}


void registerOneSignalEventListener({
  required Function(OSNotificationClickEvent result) onOpened,
  required Function(OSNotificationWillDisplayEvent) onReceivedInForeground,
}) {
 OneSignal.initialize(oneSignalAppId);

 OneSignal.Notifications.addClickListener(onOpened);
 OneSignal.Notifications.addForegroundWillDisplayListener(onReceivedInForeground);
}

const tagName = "userId";

void sendUserTag(int userId) {
  OneSignal.User.addTagWithKey(tagName, userId.toString()).then((response) {
    vLog('Successfully sent tags with response:');
  }).catchError((error) {
    vLog("Encountered an error sending tags: $error");
  });
}

void deleteUserTag() {
  OneSignal.User.removeTag(tagName).then((response) {
    vLog("Successfully deleted tags with response");
    
  }).catchError((error) {
    vLog("Encountered error deleting tag: $error");
  });
}