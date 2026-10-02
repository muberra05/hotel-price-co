import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; //mikrofon ve ses için kullanıcı izini alır
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final bool isStaff;
  const VideoCallPage({
    super.key,
    required this.channelName,
    required this.isStaff,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  static const String appId =
      "386ad8f3bbd144168b694d40cb5e1a81"; //canlı görüşme yapabilmek için AGORADAN ALDIĞIM API
  int? _remoteUid;
  RtcEngine? _engine;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted ||
        micStatus != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera & microphone permission is required.'),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.enableVideo();

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("Local user joined");
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await engine.startPreview();
    await engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: widget.isStaff ? 1 : 0, // personel 1, kullanıcı 0
      options: ChannelMediaOptions(
        clientRoleType:
            widget.isStaff
                ? ClientRoleType.clientRoleBroadcaster
                : ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    setState(() {
      _engine = engine;
      _isReady = true;
    });
  }

  Future<void> startRecording() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/start-recording'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'channelName': widget.channelName, 'uid': '12345'}),
    );

    if (response.statusCode == 200) {
      print('✅ Recording started successfully!'); //şu an aktif çalışmıyor
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Recording started ")));
    } else {
      print('Failed to start recording: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to start recording ")),
      );
    }
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Widget renderVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Center(
        child: Text("Waiting for hotel staff..."),
      ); //otel personelinde kanala bağlanması bekleniyor
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _engine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Live Video Tour")), //canlı arama başlar
      body: Stack(
        children: [
          renderVideo(),
          Positioned(
            top: 20,
            right: 20,
            width: 120,
            height: 160,
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: ElevatedButton(
              onPressed: startRecording,
              child: const Text("Start Recording"), //şu an aktif değil
            ),
          ),
        ],
      ),
    );
  }
}
