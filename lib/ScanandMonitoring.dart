import 'dart:async';
import 'package:flutter/material.dart';

class ScanAndMonitoring extends StatefulWidget {
  @override
  _ScanAndMonitoringState createState() => _ScanAndMonitoringState();
}

class _ScanAndMonitoringState extends State<ScanAndMonitoring> {
  final TextEditingController _emailController = TextEditingController();
  bool isMonitoring = false;
  String monitoringStatus = 'Not Monitoring';
  String? lastBreachDetected;

  // Simulated dark web breached emails (for testing purposes)
  final List<String> breachedEmails = [
    'user@example.com',
    'john.doe@gmail.com',
    'alice@hacked.com',
  ];

  Timer? monitoringTimer;

  @override
  void dispose() {
    monitoringTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Enter a valid email.", isError: true);
      return;
    }

    setState(() {
      isMonitoring = true;
      monitoringStatus = 'Monitoring in progress...';
    });

    monitoringTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkDarkWebBreach(email);
    });

    _showSnackBar("Monitoring started for $email");
  }

  void _stopMonitoring() {
    monitoringTimer?.cancel();
    setState(() {
      isMonitoring = false;
      monitoringStatus = 'Monitoring stopped';
    });
    _showSnackBar("Monitoring stopped", isWarning: true);
  }

  void _checkDarkWebBreach(String email) {
    if (breachedEmails.contains(email)) {
      monitoringTimer?.cancel();
      setState(() {
        isMonitoring = false;
        monitoringStatus = 'Breach Detected!';
        lastBreachDetected = email;
      });

      _showBreachAlert(email);
    } else {
      setState(() {
        monitoringStatus = 'No breach detected';
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor:
      isError ? Colors.redAccent : (isWarning ? Colors.orangeAccent : Colors.green),
    ));
  }

  void _showBreachAlert(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Breach Detected"),
          ],
        ),
        content: Text(
          "Your email '$email' has been found on dark web sources. "
              "Please update your passwords and enable two-factor authentication.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Got it", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  Widget _buildMonitorCard() {
    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: "Enter email to monitor",
                labelStyle: TextStyle(color: Colors.blueGrey),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isMonitoring ? _stopMonitoring : _startMonitoring,
              icon: Icon(isMonitoring ? Icons.stop : Icons.security),
              label: Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMonitoring ? Colors.redAccent : Colors.teal,
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
              leading: Icon(Icons.monitor_heart, color: Colors.deepPurple),
              title: Text("Monitoring Status"),
              subtitle: Text(
                monitoringStatus,
                style: TextStyle(
                  color: monitoringStatus.contains("Breach")
                      ? Colors.red
                      : Colors.black54,
                ),
              ),
            ),
            if (lastBreachDetected != null)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Compromised Email: $lastBreachDetected",
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
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
        title: Text("Dark Web Monitor"),
        backgroundColor: Color(0xFF08223A),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Added container with text right after the AppBar
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Welcome to the Dark Web Monitor. Enter your email address and keep track of any breaches detected on the dark web.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              "Protect your identity.\nMonitor dark web for exposed credentials.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 25),
            _buildMonitorCard(),
          ],
        ),
      ),
    );
  }
}
