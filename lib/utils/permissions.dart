import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<void> requestCameraAndMic() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }
}
