import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebProtectionScreen extends StatefulWidget {
  @override
  _WebProtectionScreenState createState() => _WebProtectionScreenState();
}

class _WebProtectionScreenState extends State<WebProtectionScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _result = '';
  bool _isProcessing = false;
  String _apiStatus = '🟢 API is ready to scan URLs';
  List<String> _featureExplanations = [];

  final String _apiKey = "0d7edf53572b3233b1a02fd5376919ff86e424959fb01473658c3d8c71760669";

  Future<void> checkUrlSafety(String url) async {
    if (url.isEmpty) {
      setState(() => _result = "⚠️ Please enter a URL.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = '🔍 Scanning with mobilescanner...';
      _featureExplanations = [];
    });

    try {
      final postUri = Uri.parse('https://www.virustotal.com/api/v3/urls');
      final postResponse = await http.post(
        postUri,
        headers: {
          'x-apikey': _apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'url=$url',
      );

      if (postResponse.statusCode == 200 || postResponse.statusCode == 202) {
        final responseJson = json.decode(postResponse.body);
        final analysisId = responseJson['data']['id'];

        await Future.delayed(Duration(seconds: 5)); // Wait for scan

        final getUri = Uri.parse('https://www.virustotal.com/api/v3/analyses/$analysisId');
        final getResponse = await http.get(
          getUri,
          headers: {'x-apikey': _apiKey},
        );

        if (getResponse.statusCode == 200) {
          final resultJson = json.decode(getResponse.body);
          final stats = resultJson['data']['attributes']['stats'];
          final malicious = stats['malicious'];
          final suspicious = stats['suspicious'];
          final harmless = stats['harmless'];

          setState(() {
            if (malicious > 0 || suspicious > 0) {
              _result = "⚠️ Potential Threat Detected!";
              _featureExplanations = [
                "Malicious: $malicious engines flagged this.",
                "Suspicious: $suspicious engines raised concern.",
                "Harmless: $harmless engines marked it safe."
              ];
            } else {
              _result = "✅ URL is Safe";
              _featureExplanations = [
                "No engines flagged this URL as malicious.",
                "Based on Analysis, this URL is likely safe."
              ];
            }
          });
        } else {
          setState(() {
            _result = "❌ Failed to retrieve scan result.";
            _featureExplanations = ["VirusTotal analysis request failed."];
          });
        }
      } else {
        setState(() {
          _result = "❌ Failed to submit URL to VirusTotal.";
          _featureExplanations = ["Submission failed."];
        });
      }
    } catch (e) {
      setState(() {
        _result = "❌ Error: ${e.toString()}";
        _featureExplanations = ["Failed to check URL safety."];
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void openUrl(String url) async {
    url = url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw 'Failed to launch the URL.';
        }
      } else {
        throw 'Cannot launch $url';
      }
    } catch (e) {
      setState(() => _result = "❌ Could not open URL: ${e.toString()}");
      print("Error opening URL: ${e.toString()}"); // Log the error

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open URL in browser.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSafe = _result.contains("✅");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Web Safety Checker",
          style: TextStyle(color: Colors.white), // App bar text color white
        ),
        iconTheme: IconThemeData(color: Colors.white), // App bar icon color white
        backgroundColor: Color(0xFF08223A),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Web Safety Checker - Check URL safety in seconds.")),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white, // Set background color to white for the whole page
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 👇 First Container: General Text Section
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50, // Background color of the first container (light blue)
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Row(
                  children: [
                    // Removed Icon
                    SizedBox(width: 12), // Space to maintain layout without the icon
                    Expanded(
                      child: Text(
                        "Welcome to the URL Safety Checker! Enter any URL below to check if it's safe or unsafe.",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              // 👇 Second Container: URL Input Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF10436B), // Background color of the second container (dark blue)
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2), // Subtle white shadow
                      spreadRadius: 3,
                      blurRadius: 7,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TextField with white text and appropriate styling
                    TextField(
                      controller: _urlController,
                      style: TextStyle(color: Colors.white), // White text color inside the TextField
                      cursorColor: Colors.white, // White cursor color
                      decoration: InputDecoration(
                        labelText: "Enter URL to Check",
                        labelStyle: TextStyle(color: Colors.white), // White label text
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white), // White border color
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white), // White border color even when not focused
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white), // White border color when focused
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.paste, color: Colors.white), // White icon color
                          onPressed: () async {
                            ClipboardData? data = await Clipboard.getData('text/plain');
                            if (data != null) {
                              _urlController.text = data.text ?? '';
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Centering the button using the Center widget
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => checkUrlSafety(_urlController.text.trim()),
                        icon: Icon(Icons.security),
                        label: Text("Check Safety", style: TextStyle(color: Colors.white)), // White text
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple, // Button color
                          foregroundColor: Colors.white, // Button text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // 👇 Result Section
              if (_result.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSafe ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSafe ? Colors.green : Colors.red,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result,
                        style: TextStyle(
                          fontSize: 18,
                          color: isSafe ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_featureExplanations.isNotEmpty) ...[
                        Divider(),
                        ..._featureExplanations.map((e) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(child: Text(e)),
                            ],
                          ),
                        ))
                      ]
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
