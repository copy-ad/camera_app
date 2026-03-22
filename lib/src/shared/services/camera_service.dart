import 'package:camera/camera.dart';

class CameraService {
  List<CameraDescription> _cameras = const [];

  Future<List<CameraDescription>> available() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    return _cameras;
  }
}

