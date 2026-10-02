import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_call_page.dart'; //  VideoCallPage import'u olduğundan bu yeterli

class JoinAsStaffPage extends StatefulWidget {
  const JoinAsStaffPage({super.key});

  @override
  State<JoinAsStaffPage> createState() => _JoinAsStaffPageState();
}

class _JoinAsStaffPageState extends State<JoinAsStaffPage> {
  String? _channelName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestChannelName();
  }

  // Firestore'dan son randevuyu çek
  Future<void> _fetchLatestChannelName() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('appointments')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _channelName = snapshot.docs.first['channelName'];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  // VideoCallPage'e geç
  void _goToVideoCall() {
    if (_channelName == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VideoCallPage(
              channelName: _channelName!,
              isStaff: true, // staff burada
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join as Hotel Staff")),
      body: Center(
        child:
            _loading
                ? const CircularProgressIndicator()
                : _channelName == null
                ? const Text("No appointment found.")
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Channel: $_channelName"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _goToVideoCall,
                      child: const Text("Join Video Call"),
                    ),
                  ],
                ),
      ),
    );
  }
}
