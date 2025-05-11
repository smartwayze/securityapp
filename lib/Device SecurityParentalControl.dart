import 'dart:async';
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    title: 'Parental Controls',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF08223A),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    ),
    home: const DeviceSecurityParentalControl(),
  ));
}

class DeviceSecurityParentalControl extends StatefulWidget {
  const DeviceSecurityParentalControl({Key? key}) : super(key: key);

  @override
  _DeviceSecurityParentalControlState createState() => _DeviceSecurityParentalControlState();
}

class _DeviceSecurityParentalControlState extends State<DeviceSecurityParentalControl> with WidgetsBindingObserver {
  // Security settings
  bool _appLockEnabled = false;
  bool _contentFilterEnabled = true;
  bool _screenTimeLimitsEnabled = true;
  bool _locationSharingEnabled = false;
  bool _usageMonitoringEnabled = true;

  // Parental controls
  final Map<String, bool> _appRestrictions = {
    'Social Media': true,
    'Games': true,
    'Streaming': false,
    'Browser': true,
  };

  // Location sharing
  final List<FamilyMember> _familyMembers = [
    FamilyMember('Mom', '+1234567890'),
    FamilyMember('Dad', '+1987654321'),
  ];
  Position? _lastKnownPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _appCheckTimer;
  String? _lastForegroundApp;
  Timer? _blockingTimer;

  // Schedule
  TimeOfDay _bedtimeStart = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _bedtimeEnd = const TimeOfDay(hour: 7, minute: 0);

  // Usage stats
  List<UsageInfo> _usageStats = [];
  bool _loadingStats = false;
  final List<String> _blockedKeywords = [
    'adult', 'porn', 'violence', 'gambling',
    'drugs', 'hate', 'weapons'
  ];

  // AI suggestions
  List<String> _aiSuggestions = [];
  List<Application> _installedApps = [];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    WidgetsBinding.instance.addObserver(this);
    _initializeDefaultSuggestions();
    _checkPermissions().then((_) {
      _loadUsageStats();
      _loadInstalledApps();
      _startAppMonitoring();
      if (_locationSharingEnabled) {
        _startLocationUpdates();
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _appCheckTimer?.cancel();
    _blockingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForegroundApp();
    }
  }

  void _startAppMonitoring() {
    // Check immediately
    _checkForegroundApp();

    // Then check every second
    _appCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkForegroundApp();
    });

    // Additional periodic check every 5 seconds
    _blockingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkCurrentlyUsedApp();
    });
  }

  Future<void> _checkCurrentlyUsedApp() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(seconds: 5));

      List<UsageInfo> stats = await UsageStats.queryUsageStats(startDate, endDate);
      if (stats.isNotEmpty) {
        String? currentApp = stats.first.packageName;
        if (currentApp != null) {
          await _checkAndBlockApp(currentApp);
        }
      }
    } catch (e) {
      debugPrint('Error checking currently used app: $e');
    }
  }

  Future<void> _checkForegroundApp() async {
    try {
      DateTime now = DateTime.now();
      List<UsageInfo> stats = await UsageStats.queryUsageStats(
        now.subtract(const Duration(seconds: 1)),
        now,
      );

      if (stats.isNotEmpty) {
        String? currentApp = stats.first.packageName;
        if (currentApp != null && currentApp != _lastForegroundApp) {
          _lastForegroundApp = currentApp;
          await _checkAndBlockApp(currentApp);
        }
      }
    } catch (e) {
      debugPrint('Error checking foreground app: $e');
    }
  }

  Future<void> _checkAndBlockApp(String packageName) async {
    if (!_screenTimeLimitsEnabled && !_appLockEnabled) return;

    try {
      Application? app = await DeviceApps.getApp(packageName);
      if (app == null) return;

      bool shouldBlock = _shouldBlockApp(app.appName, app.packageName);

      if (shouldBlock && mounted) {
        // Show blocking dialog
        _showAppBlockedDialog(context, app.appName, 'This app is restricted by parental controls');

        // Minimize the app
        SystemNavigator.pop();

        // Open settings instead
        await Future.delayed(const Duration(milliseconds: 500));
        await DeviceApps.openApp('com.android.settings');
      }
    } catch (e) {
      debugPrint('Error checking app: $e');
    }
  }

  bool _shouldBlockApp(String? appName, String packageName) {
    if (_appRestrictions['Social Media']! && _isSocialMediaApp(appName, packageName)) {
      return true;
    }
    if (_appRestrictions['Games']! && _isGameApp(appName, packageName)) {
      return true;
    }
    if (_appRestrictions['Browser']! && _isBrowserApp(appName, packageName)) {
      return true;
    }
    if (_appRestrictions['Streaming']! && _isStreamingApp(appName, packageName)) {
      return true;
    }
    return false;
  }

  bool _isSocialMediaApp(String? appName, String packageName) {
    final socialMediaPackages = [
      'com.facebook.katana', // Facebook
      'com.instagram.android', // Instagram
      'com.twitter.android', // Twitter
      'com.snapchat.android', // Snapchat
      'com.zhiliaoapp.musically', // TikTok
      'com.linkedin.android', // LinkedIn
      'com.pinterest', // Pinterest
      'com.reddit.frontpage', // Reddit
    ];

    final name = appName?.toLowerCase() ?? '';
    return socialMediaPackages.contains(packageName) ||
        name.contains('facebook') ||
        name.contains('instagram') ||
        name.contains('twitter') ||
        name.contains('tiktok') ||
        name.contains('snapchat') ||
        name.contains('linkedin') ||
        name.contains('pinterest') ||
        name.contains('reddit');
  }

  bool _isGameApp(String? appName, String packageName) {
    final gamePackages = [
      'com.epicgames.fortnite',
      'com.mojang.minecraftpe',
      'com.roblox.client',
      'com.activision.callofduty.shooter',
      'com.supercell.clashofclans',
      'com.supercell.clashroyale',
      'com.ea.game.pvzfree_row',
    ];

    final name = appName?.toLowerCase() ?? '';
    return gamePackages.contains(packageName) ||
        name.contains('game') ||
        packageName.contains('game') ||
        packageName.contains('unity') ||
        packageName.contains('epic') ||
        packageName.contains('playgames');
  }

  bool _isBrowserApp(String? appName, String packageName) {
    final browserPackages = [
      'com.android.chrome',
      'org.mozilla.firefox',
      'com.opera.browser',
      'com.microsoft.emmx',
      'com.brave.browser',
      'com.sec.android.app.sbrowser',
    ];

    final name = appName?.toLowerCase() ?? '';
    return browserPackages.contains(packageName) ||
        name.contains('browser') ||
        name.contains('chrome') ||
        name.contains('firefox') ||
        name.contains('explorer') ||
        name.contains('web') ||
        name.contains('edge') ||
        name.contains('opera');
  }

  bool _isStreamingApp(String? appName, String packageName) {
    final streamingPackages = [
      'com.netflix.mediaclient',
      'com.google.android.youtube',
      'com.amazon.avod.thirdpartyclient',
      'com.disney.disneyplus',
      'com.hbo.hbonow',
      'com.spotify.music',
      'com.apple.android.music',
    ];

    final name = appName?.toLowerCase() ?? '';
    return streamingPackages.contains(packageName) ||
        name.contains('netflix') ||
        name.contains('youtube') ||
        name.contains('prime') ||
        name.contains('disney') ||
        name.contains('hbo') ||
        name.contains('spotify') ||
        name.contains('music');
  }

  void _showAppBlockedDialog(BuildContext context, String? appName, String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('$appName Blocked'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPermissions() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();
    await Permission.sms.request();
  }

  Future<void> _loadInstalledApps() async {
    try {
      List<Application> apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: true,
      );

      setState(() {
        _installedApps = apps;
      });
    } catch (e) {
      debugPrint("Error loading installed apps: $e");
    }
  }

  void _initializeDefaultSuggestions() {
    setState(() {
      _aiSuggestions = [
        "Consider enabling app lock for banking apps",
        "Review daily usage patterns",
      ];
    });
  }

  Future<void> _loadUsageStats() async {
    if (!mounted) return;

    setState(() {
      _loadingStats = true;
      _aiSuggestions = ["Loading usage data..."];
    });

    try {
      if (await Permission.activityRecognition.isGranted) {
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 1));

        List<UsageInfo> stats = await UsageStats.queryUsageStats(
          startDate,
          endDate,
        );

        stats = stats.where((stat) => stat.firstTimeStamp != null).toList();

        if (!mounted) return;
        setState(() {
          _usageStats = stats;
          _loadingStats = false;
        });

        _analyzeUsagePatterns();
      } else {
        if (!mounted) return;
        setState(() {
          _loadingStats = false;
          _aiSuggestions.add("Usage stats permission not granted");
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStats = false;
        _aiSuggestions.add("Error loading usage data: ${e.toString()}");
      });
      debugPrint("Error loading usage stats: $e");
    }
  }

  void _analyzeUsagePatterns() {
    final newSuggestions = <String>[];
    final appUsage = <String, Duration>{};

    for (final stat in _usageStats) {
      final duration = _calculateUsageDuration(stat);
      final packageName = stat.packageName ?? 'unknown';
      appUsage.update(
        packageName,
            (value) => value + duration,
        ifAbsent: () => duration,
      );

      final time = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(stat.firstTimeStamp?.toString() ?? '0') ?? 0
      );

      if (time.hour >= _bedtimeStart.hour || time.hour <= _bedtimeEnd.hour) {
        newSuggestions.add('Night time usage detected for $packageName');
      }
    }

    appUsage.forEach((package, duration) {
      if (duration.inHours >= 2) {
        newSuggestions.add('Limit usage of $package (used for ${duration.inHours} hours)');
      }
    });

    setState(() {
      _aiSuggestions = newSuggestions.isNotEmpty ? newSuggestions : ['Usage patterns look healthy'];
    });
  }

  Duration _calculateUsageDuration(UsageInfo stat) {
    return Duration(milliseconds: int.tryParse(stat.totalTimeInForeground?.toString() ?? '0') ?? 0);
  }

  Future<void> _toggleLocationSharing(bool value) async {
    if (value) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
          return;
        }
      }

      _startLocationUpdates();
    } else {
      _stopLocationUpdates();
    }

    if (!mounted) return;
    setState(() => _locationSharingEnabled = value);
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 100,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!mounted) return;
      setState(() => _lastKnownPosition = position);
    });
  }

  void _stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _shareLocationWith(FamilyMember member) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are required')),
        );
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query='
          '${position.latitude},${position.longitude}';

      final message = 'My current location: $mapsUrl\n'
          'Coordinates: ${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}\n'
          'Time: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

      final smsUri = Uri(
        scheme: 'sms',
        path: member.phone,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location shared with ${member.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF08223A),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch messaging app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
      debugPrint('Error sharing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Parental Controls', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
        backgroundColor: const Color(0xFF08223A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSecuritySettingsCard(),
            const SizedBox(height: 16),
            _buildParentalControlsCard(),
            const SizedBox(height: 16),
            _buildAISuggestionsCard(),
            const SizedBox(height: 16),
            _buildUsageStatsCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF08223A),
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _loadUsageStats,
        tooltip: 'Refresh data',
      ),
    );
  }

  Widget _buildSecuritySettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08223A),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('App Lock'),
              contentPadding: EdgeInsets.zero,
              value: _appLockEnabled,
              onChanged: (value) => setState(() => _appLockEnabled = value),
            ),
            SwitchListTile(
              title: const Text('Content Filter'),
              contentPadding: EdgeInsets.zero,
              value: _contentFilterEnabled,
              onChanged: (value) => setState(() => _contentFilterEnabled = value),
            ),
            SwitchListTile(
              title: const Text('Screen Time Limits'),
              contentPadding: EdgeInsets.zero,
              value: _screenTimeLimitsEnabled,
              onChanged: (value) => setState(() => _screenTimeLimitsEnabled = value),
            ),
            _buildLocationSharingSection(),
            SwitchListTile(
              title: const Text('Usage Monitoring'),
              contentPadding: EdgeInsets.zero,
              value: _usageMonitoringEnabled,
              onChanged: (value) => setState(() => _usageMonitoringEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSharingSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Share My Location'),
          contentPadding: EdgeInsets.zero,
          value: _locationSharingEnabled,
          onChanged: _toggleLocationSharing,
        ),
        if (_locationSharingEnabled) ...[
          const SizedBox(height: 12),
          const Text('Shared with:', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._familyMembers.map((member) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF08223A),
              child: Text(member.name[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(member.name),
            subtitle: Text(member.phone),
            trailing: IconButton(
              icon: const Icon(Icons.location_on, color: Color(0xFF08223A)),
              onPressed: () => _shareLocationWith(member),
            ),
          )),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF08223A)),
            child: const Text('Add Family Member'),
            onPressed: _addFamilyMember,
          ),
          if (_lastKnownPosition != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last location: ${_lastKnownPosition!.latitude.toStringAsFixed(4)}, '
                    '${_lastKnownPosition!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildParentalControlsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parental Controls',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08223A)),
            ),
            const SizedBox(height: 12),
            ..._appRestrictions.entries.map((entry) => SwitchListTile(
              title: Text('Restrict ${entry.key}'),
              contentPadding: EdgeInsets.zero,
              value: entry.value,
              onChanged: (value) => setState(() => _appRestrictions[entry.key] = value),
            )),
            const SizedBox(height: 16),
            _buildBedtimeScheduleSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBedtimeScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bedtime Schedule',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Time',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bedtimeStart.format(context),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Time',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bedtimeEnd.format(context),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_bedtimeStart.hour >= _bedtimeEnd.hour)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '⚠️ End time should be after start time',
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildAISuggestionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Suggestions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08223A)),
            ),
            const SizedBox(height: 12),
            if (_aiSuggestions.isEmpty)
              const Text(
                'No suggestions at this time',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._aiSuggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Statistics',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08223A)),
            ),
            const SizedBox(height: 12),
            if (_loadingStats)
              const Center(child: CircularProgressIndicator())
            else if (_usageStats.isEmpty)
              const Text(
                'No usage data available',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: [
                  const Text(
                    'Recent App Usage:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._usageStats.take(5).map((stat) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                        int.tryParse(stat.firstTimeStamp?.toString() ?? '0') ?? 0
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              stat.packageName ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${DateFormat('HH:mm').format(date)} - '
                                '${_calculateUsageDuration(stat).inMinutes} mins',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_usageStats.length > 5)
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF08223A)),
                      child: const Text('Show More'),
                      onPressed: () => _showAllUsageStats(context),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _bedtimeStart : _bedtimeEnd,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF08223A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              dayPeriodTextColor: Colors.black,
              dialHandColor: const Color(0xFF08223A),
              dialBackgroundColor: Colors.grey[200],
              hourMinuteColor: Colors.grey[200],
              entryModeIconColor: const Color(0xFF08223A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStartTime) {
          _bedtimeStart = picked;
        } else {
          _bedtimeEnd = picked;
        }
      });

      if (_bedtimeStart.hour >= _bedtimeEnd.hour) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please ensure end time is after start time'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addFamilyMember() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08223A)),
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  _familyMembers.add(FamilyMember(
                    nameController.text,
                    phoneController.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAllUsageStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Usage Stats'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _usageStats.length,
            itemBuilder: (context, index) {
              final stat = _usageStats[index];
              final date = DateTime.fromMillisecondsSinceEpoch(
                  int.tryParse(stat.firstTimeStamp?.toString() ?? '0') ?? 0
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        stat.packageName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormat('MMM d').format(date),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_calculateUsageDuration(stat).inMinutes} mins',
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class FamilyMember {
  final String name;
  final String phone;
  final bool isAdmin;

  FamilyMember(this.name, this.phone, {this.isAdmin = false});
}