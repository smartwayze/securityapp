import 'dart:math';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart'; // For biometric authentication

class PasswordManager extends StatefulWidget {
  @override
  _PasswordManagerState createState() => _PasswordManagerState();
}

class _PasswordManagerState extends State<PasswordManager> {
  bool isLoggedIn = false;
  String statusMessage = "Awaiting login...";
  String simulatedDeviceId = "DEVICE_001";
  final Random _random = Random();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Simulated mobile device lock state
  bool isDeviceLocked = false;
  String currentDeviceId = "";
  String? generatedOtp;

  void _attemptLogin() async {
    // Generate random device ID (simulate different device sometimes)
    currentDeviceId = _random.nextInt(100) < 80 ? "DEVICE_001" : "DEVICE_999";

    // Check if device is locked (simulated)
    isDeviceLocked = await _checkDeviceLockStatus();

    if (isDeviceLocked) {
      // If device is locked, require biometric authentication first
      bool authenticated = await _authenticateWithBiometrics();
      if (!authenticated) {
        setState(() {
          statusMessage = "Biometric authentication failed. Access denied.";
        });
        return;
      }
    }

    bool unusualAttempt = _simulateUnusualLogin();

    if (unusualAttempt) {
      // Generate and "send" OTP to device
      generatedOtp = _generateOtp();
      _showOtpOnDeviceLockScreen(generatedOtp!);

      _showMultiFactorDialog();
    } else {
      setState(() {
        isLoggedIn = true;
        statusMessage = "Login successful (Normal behavior)";
      });
    }
  }

  // Simulate checking if device is locked
  Future<bool> _checkDeviceLockStatus() async {
    // In real app, this would check actual device lock status
    return _random.nextBool(); // 50% chance device is locked
  }

  // Simulate biometric authentication
  Future<bool> _authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access password manager',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Simulated AI-based check for unusual login behavior
  bool _simulateUnusualLogin() {
    int currentHour = DateTime.now().hour;
    bool isLateNight = currentHour < 6 || currentHour > 22;
    bool isNewDevice = currentDeviceId != simulatedDeviceId;
    bool isForeignLocation = _random.nextInt(100) < 20; // 20% chance

    // Simulate AI: flag as unusual if late night, device changed, or foreign location
    return isLateNight || isNewDevice || isForeignLocation;
  }

  String _generateOtp() {
    return (100000 + _random.nextInt(900000)).toString(); // 6-digit OTP
  }

  // Simulate showing OTP on device lock screen
  void _showOtpOnDeviceLockScreen(String otp) {
    // In a real app, this would use platform channels to display on lock screen
    debugPrint("OTP $otp displayed on device lock screen");

    // For demo purposes, we'll also show it in the UI
    setState(() {
      statusMessage = "⚠️ Suspicious activity detected\nOTP sent to your device: $otp";
    });
  }

  void _showMultiFactorDialog() {
    TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("⚠️ Additional Authentication Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Unusual login behavior detected.\nPlease enter the OTP sent to your device:"),
            SizedBox(height: 12),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text("Verify", style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (otpController.text == generatedOtp) {
                setState(() {
                  isLoggedIn = true;
                  statusMessage = "Login successful after OTP verification";
                });
                Navigator.pop(context);
              } else {
                setState(() {
                  statusMessage = "Invalid OTP. Login denied.";
                });
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security_rounded, size: 60, color: Colors.teal),
            SizedBox(height: 20),
            Text(
              isLoggedIn ? "✔️ Logged In" : "🔐 Not Logged In",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _attemptLogin,
              icon: Icon(Icons.login),
              label: Text("Login Securely"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              statusMessage,
              style: TextStyle(
                color: isLoggedIn ? Colors.green : Colors.black87,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (generatedOtp != null && !isLoggedIn) ...[
              SizedBox(height: 16),
              Text(
                "Check your device lock screen for OTP",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text("Password Manager"),
        backgroundColor: Color(0xFF08223A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildLoginCard(),
        ),
      ),
    );
  }
}