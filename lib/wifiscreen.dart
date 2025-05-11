import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WiFiScannerHome extends StatefulWidget {
  @override
  _WiFiScannerHomeState createState() => _WiFiScannerHomeState();
}

class _WiFiScannerHomeState extends State<WiFiScannerHome> {
  static const platform = MethodChannel('com.yourapp.wifi');  // Define the channel

  List<WiFiAccessPoint> _wifiList = [];
  bool _isLoading = false;

  Future<void> _scanWiFi() async {
    setState(() {
      _isLoading = true;
    });

    final can = await WiFiScan.instance.canStartScan();
    if (can != CanStartScan.yes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to start scan: $can")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();

    setState(() {
      _wifiList = results;
      _isLoading = false;
    });
  }

  Future<void> _connectToWiFi(String ssid, String password) async {
    try {
      final result = await platform.invokeMethod('connectToWiFi', {
        'ssid': ssid,
        'password': password,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connecting to $ssid: $result")),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to Wi-Fi: ${e.message}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scanWiFi(); // Automatically scan on app start
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF08223A),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Wi-Fi Scanner',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Proper back navigation
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Card
              Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.blue[200]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Available Wi-Fi Networks",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Scan and connect to your desired network!",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              if (_isLoading)
                Center(child: CircularProgressIndicator()),

              if (!_isLoading && _wifiList.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.black45, size: 50),
                      SizedBox(height: 10),
                      Text(
                        "No Wi-Fi networks found in this area.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_isLoading && _wifiList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _wifiList.length,
                    itemBuilder: (context, index) {
                      final wifi = _wifiList[index];
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            wifi.ssid ?? "Unknown Network",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          leading: Icon(Icons.wifi, color: Colors.deepPurple),
                          subtitle: Text(
                            "Signal Strength: ${wifi.level ?? 'N/A'} dBm",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                          onTap: () {
                            // Prompt for password and then connect
                            _showPasswordDialog(wifi.ssid);
                          },
                        ),
                      );
                    },
                  ),
                ),

              SizedBox(height: 20),

              // Scan Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _scanWiFi,
                  child: Icon(
                    Icons.wifi,
                    color: Colors.white,
                    size: 30, // Adjust icon size for a more compact look
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blueAccent, // Text/icon color
                    shape: CircleBorder(), // Makes the button circular
                    padding: EdgeInsets.all(18), // Adjust padding to make the button smaller
                    elevation: 10, // Gives it a subtle floating effect
                    shadowColor: Colors.deepPurple.withOpacity(0.5), // Shadow effect
                  ),
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Password dialog to prompt user for network password
  void _showPasswordDialog(String ssid) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter password for $ssid"),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(hintText: "Password"),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _connectToWiFi(ssid, passwordController.text);
                Navigator.pop(context);
              },
              child: Text("Connect"),
            ),
          ],
        );
      },
    );
  }
}
