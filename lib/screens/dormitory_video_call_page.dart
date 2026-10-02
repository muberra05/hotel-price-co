/*import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class DormitoryVideoCallPage extends StatefulWidget {
  final String dormId;
  final String dormName;
  final String userName;

  const DormitoryVideoCallPage({
    Key? key,
    required this.dormId,
    required this.dormName,
    required this.userName,
  }) : super(key: key);

  @override
  State<DormitoryVideoCallPage> createState() => _DormitoryVideoCallPageState();
}

class _DormitoryVideoCallPageState extends State<DormitoryVideoCallPage> {
  static const String appId = '4f2b0329e7ac4e8c9ba802d8fdf93da0';
  static const String token = ''; // token kullanmıyorsan boş bırak
  late final RtcEngine _engine;
  bool _isJoined = false;
  List<int> _remoteUids = [];

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Kamera ve mikrofon izinleri iste
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
          });
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          setState(() {
            _remoteUids.remove(remoteUid);
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview(); // ✅ KENDİ GÖRÜNTÜNÜ GÖSTER
    await _engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await _engine.joinChannel(
      token: token,
      channelId: widget.dormId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Call: ${widget.dormName}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          _isJoined
              ? _buildVideoView()
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                _engine.leaveChannel();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('End Call'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    return Stack(
      children: [
        if (_remoteUids.isNotEmpty)
          ..._remoteUids.map(
            (uid) => Positioned.fill(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: uid),
                  connection: RtcConnection(channelId: widget.dormId),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            height: 150,
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
*/
