import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'webprotectionscreen.dart';
import 'smartcrossprotection.dart';
import 'wifiscreen.dart';
import 'package:mobileSecurityapp/Antivirus&malwarescreen.dart';
import 'ScanandMonitoring.dart';
import 'securevpn.dart';
import 'VulnerabilityScanning.dart';
import 'passwordmanager.dart';
import 'callblock.dart';
import 'DataEncryption.dart';
import 'Privacyadvisor.dart';
import 'Device SecurityParentalControl.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color backgroundColor = Color(0xFF08223A);
  final Color cardColor = Color(0xFF10436B);

  bool scanDevices = true;
  bool cloudStorage = false;
  bool trackingSoftware = true;

  String lastScan = '';
  bool isScanning = false;
  List<double> scanResults = [3, 5, 7, 4, 6]; // Default scan results

  @override
  void initState() {
    super.initState();
    updateLastScanTime();
  }

  void updateLastScanTime() {
    final now = DateTime.now();
    lastScan = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  void startScan() async {
    setState(() {
      isScanning = true;
    });

    // Simulating the scanning process
    await Future.delayed(Duration(seconds: 3)); // Wait for 3 seconds to simulate scan
    setState(() {
      isScanning = false;
      // Update the scan results with random values (simulating a scan result)
      scanResults = List.generate(5, (index) => (index + 1) * (index % 3 == 0 ? 1 : 2));
      updateLastScanTime();
    });

    // Show a popup message after the scan
    _showScanResultDialog();
  }

  void _showScanResultDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Scan Completed'),
          content: Text(
            'Successfully scanned, your device is protected.\n\nLast scan was at $lastScan',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showViewAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('View All Threat Statistics'),
          content: Text(
            'Here you can show more detailed statistics about the threats. This is where you can display additional information.',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = screenHeight > screenWidth;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/image2.webp'),
                    radius: screenWidth * 0.06,
                  ),
                  Icon(Icons.lock_outline, color: Colors.white),
                ],
              ),
            ),

            // Protection Info Banner (full width)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'This device is protected',
                    style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Last scan at $lastScan',
                    style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.03),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: startScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2B84F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    child: isScanning
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Start scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Security elements',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Feature Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FeatureBanner(),
                    ),

                    // Threat Statistics
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Threat statistics',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showViewAllDialog,
                            child: Text(
                              'View all',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bar Chart
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      height: screenHeight * 0.25,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 10,
                            barGroups: [
                              makeGroupData(0, scanResults[0]),
                              makeGroupData(1, scanResults[1]),
                              makeGroupData(2, scanResults[2]),
                              makeGroupData(3, scanResults[3]),
                              makeGroupData(4, scanResults[4]),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                                    return Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        days[value.toInt()],
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: screenWidth * 0.03,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 2,
                              verticalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.white30,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: Colors.white30,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF0C2E4E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white54,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: screenWidth * 0.03,
                  unselectedFontSize: screenWidth * 0.03,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.security),
                      label: 'Security',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.vpn_key),
                      label: 'Password',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.cloud),
                      label: 'My cloud',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 12,
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }
}

class FeatureBanner extends StatefulWidget {
  @override
  _FeatureBannerState createState() => _FeatureBannerState();
}

class _FeatureBannerState extends State<FeatureBanner> {
  final List<Map<String, dynamic>> features = [
    {"icon": Icons.web, "text": "AI-powered Web Protection & Safe Browsing"},
    {"icon": Icons.phonelink_lock, "text": "Smart Cross-Platform Protection"},
    {"icon": Icons.wifi, "text": "Wi-Fi Scan"},
    {"icon": Icons.security, "text": "Antivirus & Malware Detection"},
    {"icon": Icons.fingerprint, "text": "Identity Scan & Monitoring"},
    {"icon": Icons.vpn_key, "text": "Secure VPN with AI Traffic Analysis"},
    {"icon": Icons.bug_report, "text": "Vulnerability Scanning & Security Audit"},
    {"icon": Icons.lock, "text": "Password Manager & Two-Factor Authentication"},
    {"icon": Icons.call_missed, "text": "Call Filter & Call Blocker with AI Detection"},
    {"icon": Icons.enhanced_encryption, "text": "Data Encryption & AI-driven App Lock"},
    {"icon": Icons.verified_user, "text": "Privacy Advisor & Security Advisor"},
    {"icon": Icons.security, "text": "Device Security Settings & Parental Control"},
    {"icon": Icons.verified, "text": "AI-Driven Identity Protection & Monitoring"},
    {"icon": Icons.mic, "text": "Microphone Protection & App Permission Manager"},
    {"icon": Icons.center_focus_strong, "text": "QR Scanner with Threat Detection"},
  ];

  final PageController _pageController = PageController();
  final int itemsPerPage = 9;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = screenHeight > screenWidth;
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Container(
          height: isPortrait ? screenHeight * 0.43 : screenHeight * 0.5,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: (features.length / itemsPerPage).ceil(),
            itemBuilder: (context, pageIndex) {
              return GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isPortrait ? 3 : 4,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: isPortrait ? 0.9 : 1.2,
                ),
                itemCount: min(itemsPerPage, features.length - pageIndex * itemsPerPage),
                itemBuilder: (context, index) {
                  final featureIndex = pageIndex * itemsPerPage + index;
                  return _buildFeatureItem(features[featureIndex]);
                },
              );
            },
          ),
        ),
        SizedBox(height: 10),
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: (features.length / itemsPerPage).ceil(),
            effect: WormEffect(
              dotWidth: 8,
              dotHeight: 8,
              spacing: 6,
              activeDotColor: Colors.blueAccent,
              dotColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    int featureIndex = features.indexOf(feature);

    return GestureDetector(
      onTap: () {
        switch (featureIndex) {
          case 0:
            Navigator.push(context, MaterialPageRoute(builder: (context) => WebProtectionScreen()));
            break;
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (context) => SmartCrossProtectionScreen()));
            break;
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (context) => WiFiScannerHome()));
            break;
          case 3:
            Navigator.push(context, MaterialPageRoute(builder: (context) => AntivirusAndMalwareScreen()));
            break;
          case 4:
            Navigator.push(context, MaterialPageRoute(builder: (context) => ScanAndMonitoring()));
            break;
          case 5:
            Navigator.push(context, MaterialPageRoute(builder: (context) => SecureVPN()));
            break;
          case 6:
            Navigator.push(context, MaterialPageRoute(builder: (context) => VulnerabilityScanning()));
            break;
          case 7:
            Navigator.push(context, MaterialPageRoute(builder: (context) => PasswordManager()));
            break;
          case 8:
            Navigator.push(context, MaterialPageRoute(builder: (context) => CallBlockScreen()));
            break;
          case 9:
            Navigator.push(context, MaterialPageRoute(builder: (context) => EncryptionScreen()));
            break;
          case 10:
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyAdvisorPage()));
            break;
          case 11:
            Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceSecurityParentalControl()));
            break;

        }
      },
      child: Container(
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              feature["icon"],
              color: Colors.black,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              feature["text"],
              style: TextStyle(
                color: Colors.black,
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}