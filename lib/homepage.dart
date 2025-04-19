import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

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
                    backgroundImage: AssetImage('assests/image2.webp'),
                    radius: 22,
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
                      fontSize: 18, // Increase font size
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Last scan at $lastScan',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: startScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2B84F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: isScanning
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Start scan',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Toggles
            buildSecurityTile(Icons.devices, 'Scanning devices', 'Search for malware', scanDevices, (val) {
              setState(() => scanDevices = val);
            }),
            buildSecurityTile(Icons.cloud_outlined, 'Cloud storage', 'Transferring files from a device', cloudStorage, (val) {
              setState(() => cloudStorage = val);
            }),
            buildSecurityTile(Icons.shield, 'Tracking software', 'Protect your privacy', trackingSoftware, (val) {
              setState(() => trackingSoftware = val);
            }),

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
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showViewAllDialog, // Open the dialog when tapped
                    child: Text(
                      'View all',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
            // Bar Chart
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              height: 180, // Increased height
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
                            return Text(
                              days[value.toInt()],
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true, horizontalInterval: 2, verticalInterval: 1),
                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.white30, width: 1)),
                  ),
                ),
              ),
            ),

            Spacer(),

            // Bottom Navigation Bar
            BottomNavigationBar(
              backgroundColor: Color(0xFF0C2E4E),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Security'),
                BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: 'Password'),
                BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'My cloud'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSecurityTile(
      IconData icon,
      String title,
      String subtitle,
      bool isEnabled,
      Function(bool) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: Colors.greenAccent,
            )
          ],
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        width: 12,
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(4),
      )
    ]);
  }
}
