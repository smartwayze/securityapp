import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SecureVPN extends StatefulWidget {
  @override
  _SecureVPNState createState() => _SecureVPNState();
}

class _SecureVPNState extends State<SecureVPN> {
  bool isVpnConnected = false;
  String vpnStatus = 'Disconnected';
  String trafficAnalysisStatus = 'Waiting for Traffic...';
  Timer? trafficTimer;

  // AI Simulation Parameters
  final Random _random = Random();
  final int suspiciousTrafficThreshold = 80;

  @override
  void dispose() {
    trafficTimer?.cancel();
    super.dispose();
  }

  void _connectVPN() {
    setState(() {
      isVpnConnected = true;
      vpnStatus = 'Connected';
      trafficAnalysisStatus = 'Analyzing traffic...';
    });
    _startTrafficAnalysis();
  }

  void _disconnectVPN() {
    setState(() {
      isVpnConnected = false;
      vpnStatus = 'Disconnected';
      trafficAnalysisStatus = 'Waiting for Traffic...';
    });
    trafficTimer?.cancel();
  }

  void _startTrafficAnalysis() {
    trafficTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _analyzeTrafficPattern();
    });
  }

  void _analyzeTrafficPattern() {
    final int trafficVolume = _random.nextInt(100);

    if (trafficVolume > suspiciousTrafficThreshold) {
      setState(() {
        trafficAnalysisStatus = 'Suspicious Traffic Detected: Volume $trafficVolume';
      });
      _flagSuspiciousTraffic();
    } else {
      setState(() {
        trafficAnalysisStatus = 'Traffic is Safe: Volume $trafficVolume';
      });
    }
  }

  void _flagSuspiciousTraffic() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        contentPadding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text("Suspicious Traffic Detected"),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            "The VPN traffic volume is suspiciously high. Please review your connection or take immediate action.",
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnectVPN();
            },
            child: Text(
              "Disconnect",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVpnConnectionCard() {
    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: isVpnConnected ? _disconnectVPN : _connectVPN,
              icon: Icon(isVpnConnected ? Icons.vpn_lock : Icons.vpn_key),
              label: Text(isVpnConnected ? "Disconnect VPN" : "Connect VPN"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isVpnConnected ? Colors.redAccent : Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
            SizedBox(height: 20),
            Divider(height: 1),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.lock_outline, color: Colors.deepPurple),
              title: Text("VPN Status"),
              subtitle: Text(vpnStatus),
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.blue),
              title: Text("Traffic Analysis"),
              subtitle: Text(trafficAnalysisStatus),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF3F6),
      appBar: AppBar(
        title: Text("Secure VPN"),
        backgroundColor: Color(0xFF08223A),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF08223A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Secure your connection.\nAI-based VPN traffic analysis.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 25),
            _buildVpnConnectionCard(),
          ],
        ),
      ),
    );
  }
}
