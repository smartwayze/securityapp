import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyAdvisorPage extends StatefulWidget {
  @override
  _PrivacyAdvisorPageState createState() => _PrivacyAdvisorPageState();
}

class _PrivacyAdvisorPageState extends State<PrivacyAdvisorPage> {
  final Color _primaryColor = const Color(0xFF08223A);

  final List<SecurityTip> _tips = [
    SecurityTip(
      title: 'Strong Passwords',
      description: 'Use complex passwords with a mix of letters, numbers, and symbols.',
      icon: Icons.lock,
      level: SecurityLevel.high,
    ),
    SecurityTip(
      title: 'Two-Factor Authentication',
      description: 'Enable 2FA for an extra layer of security on your accounts.',
      icon: Icons.security,
      level: SecurityLevel.critical,
    ),
    SecurityTip(
      title: 'Regular Updates',
      description: 'Keep your apps and operating system updated to patch vulnerabilities.',
      icon: Icons.system_update,
      level: SecurityLevel.high,
    ),
    SecurityTip(
      title: 'Privacy Settings',
      description: 'Review and adjust privacy settings on your apps and social media.',
      icon: Icons.settings,
      level: SecurityLevel.medium,
    ),
    SecurityTip(
      title: 'Secure Connections',
      description: 'Only use websites with HTTPS and avoid public Wi-Fi for sensitive transactions.',
      icon: Icons.wifi,
      level: SecurityLevel.high,
    ),
  ];

  int _currentTipIndex = 0;
  bool _scanComplete = false;
  double _securityScore = 0.0;
  bool _isScanning = false;
  Map<String, bool> _scanResults = {};

  @override
  void initState() {
    super.initState();
    _calculateInitialSecurityScore();
  }

  void _calculateInitialSecurityScore() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _securityScore = 0.65;
        _scanComplete = true;
      });
    });
  }

  void _nextTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
    });
  }

  void _previousTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex - 1) % _tips.length;
    });
  }

  Future<void> _launchPrivacyGuide() async {
    const url = 'https://example.com/privacy-guide';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _runQuickScan() async {
    setState(() {
      _isScanning = true;
      _scanComplete = false;
    });

    // Simulate scanning different security aspects
    await Future.delayed(const Duration(seconds: 1));

    final random = Random();
    final newResults = {
      'Screen Lock': random.nextDouble() > 0.3,
      'Biometric Auth': random.nextDouble() > 0.5,
      'OS Updated': random.nextDouble() > 0.4,
      'App Permissions': random.nextDouble() > 0.6,
      'Encryption': random.nextDouble() > 0.7,
      'Network Security': random.nextDouble() > 0.5,
    };

    final positiveResults = newResults.values.where((val) => val).length;
    final newScore = positiveResults / newResults.length;

    setState(() {
      _scanResults = newResults;
      _securityScore = newScore;
      _scanComplete = true;
      _isScanning = false;
    });

    _showScanResultsDialog();
  }

  void _showScanResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Scan Results'),
        content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._scanResults.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.error,
                        color: entry.value ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Text(
                  'New Security Score: ${(_securityScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(_securityScore),
                  ),
                ),
              ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy & Security Advisor',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _launchPrivacyGuide,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Your Security Score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _isScanning
                        ? const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Scanning your device...'),
                      ],
                    )
                        : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: _securityScore,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getScoreColor(_securityScore),
                            ),
                          ),
                        ),
                        Text(
                          '${(_securityScore * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getScoreMessage(_securityScore),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Tip',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            _tips[_currentTipIndex].icon,
                            color: _getLevelColor(_tips[_currentTipIndex].level),
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tips[_currentTipIndex].title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tips[_currentTipIndex].description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _previousTip,
                            style: TextButton.styleFrom(
                              foregroundColor: _primaryColor,
                            ),
                            child: const Text('Previous'),
                          ),
                          TextButton(
                            onPressed: _nextTip,
                            style: TextButton.styleFrom(
                              foregroundColor: _primaryColor,
                            ),
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 46),
            ElevatedButton(
              onPressed: _isScanning ? null : _runQuickScan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isScanning
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Scanning...'),
                ],
              )
                  : const Text(
                'Run Quick Security Check',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getLevelColor(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.critical:
        return Colors.red;
      case SecurityLevel.high:
        return Colors.orange;
      case SecurityLevel.medium:
        return Colors.blue;
      case SecurityLevel.low:
        return Colors.green;
    }
  }

  String _getScoreMessage(double score) {
    if (score >= 0.9) return 'Excellent! Your security practices are top-notch.';
    if (score >= 0.7) return 'Good job! You have strong security habits.';
    if (score >= 0.5) return 'Fair. Consider improving some security areas.';
    return 'Needs improvement. Please review the security tips below.';
  }
}

class SecurityTip {
  final String title;
  final String description;
  final IconData icon;
  final SecurityLevel level;

  SecurityTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.level,
  });
}

enum SecurityLevel {
  critical,
  high,
  medium,
  low,
}