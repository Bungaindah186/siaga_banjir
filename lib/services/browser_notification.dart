import 'browser_notification_stub.dart'
    if (dart.library.js_interop) 'browser_notification_web.dart'
    as platform;

Future<bool> requestBrowserNotificationPermission() {
  return platform.requestBrowserNotificationPermission();
}