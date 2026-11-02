import 'dart:js_interop';

@JS('Notification')
external JSObject get _browserNotification;

@JS()
extension type _NotificationConstructor(JSObject _) implements JSObject {
  external JSPromise<JSString> requestPermission();
}

Future<bool> requestBrowserNotificationPermission() async {
  try {
    final notification =
        _NotificationConstructor(_browserNotification);

    final permission =
        await notification.requestPermission().toDart;

    return permission.toDart == 'granted';
  } catch (e) {
    return false;
  }
}