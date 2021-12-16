import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();// runAppが実行される前に、cameraプラグインを初期化
  final cameras = await availableCameras();// デバイスで使用可能なカメラの一覧を取得する
  print(cameras);
  final firstCamera = cameras.first;// 利用可能なカメラの一覧から、指定のカメラを取得する
  runApp(MyApp(camera: firstCamera));//メイン関数
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({Key? key, required this.camera}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'camera_demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CameraHome(
        camera: camera,
      ),
    );
  }
}
class CameraHome extends StatefulWidget {
  final CameraDescription camera;

  const CameraHome({Key? key, required this.camera}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CameraHomeState();
}

class CameraHomeState extends State<CameraHome> {
  static const platform = const MethodChannel('samples.flutter.dev/battery');
  late StreamSubscription _intentDataStreamSubscription;

  late CameraController _cameraController;// デバイスのカメラを制御するコントローラ
  late Future<void> _initializeCameraController;// コントローラーに設定されたカメラを初期化する関数

  @override
  void initState() {
    super.initState();
    // コントローラを初期化 使用するカメラをコントローラに設定
    _cameraController = CameraController(
        widget.camera,
        // low : 352x288 on iOS, 240p (320x240) on Android// 使用する解像度を設定
        // medium : 480p (640x480 on iOS, 720x480 on Android)
        // high : 720p (1280x720)
        // veryHigh : 1080p (1920x1080)
        // ultraHigh : 2160p (3840x2160)
        // max : 利用可能な最大の解像度
        ResolutionPreset.max);
    _initializeCameraController = _cameraController.initialize();// コントローラーに設定されたカメラを初期化
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: FutureBuilder<void>(
        future: _initializeCameraController,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // カメラの初期化が完了したら、プレビューを表示
            return CameraPreview(_cameraController);
          } else {
            // カメラの初期化中はインジケーターを表示
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.videocam),
        // ボタンが押下された際動画撮影
        //////////////////下記で解説/////////////////////////
        onPressed: () async {
          try {
            //カメラの初期化がなされていない場合抜ける
            if (!_cameraController.value.isInitialized) {
              print("初期化ができていません。");
              return;
            }
            //すでにカメラの録画が始まっている際には録画をストップしてjavaをcall
            if (_cameraController.value.isRecordingVideo) {
              print("動画撮影終了");
              final path = await _cameraController.stopVideoRecording();//カメラを止める＆保存
              print(path.path);
              return;
            }
            final Directory appDirectory = await getApplicationDocumentsDirectory();
            final String videoDirectory = '${appDirectory.path}/video';//内部ストレージ用のフォルダpath
            await Directory(videoDirectory).create(recursive: true);//内部ストレージ用のフォルダ作成
            final String filePath = '$videoDirectory/test.mp4';//内部ストレージに保存する用のpath
            print(filePath);//ここで表示されるpathに動画が入っている
            try {
              await _cameraController.startVideoRecording();
              print("動画撮影開始");
            } on CameraException catch (e) {
              print("動画撮影ができません");
            }
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}
