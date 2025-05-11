import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SmartCrossProtectionScreen extends StatefulWidget {
  @override
  _SmartCrossProtectionScreenState createState() =>
      _SmartCrossProtectionScreenState();
}

class _SmartCrossProtectionScreenState
    extends State<SmartCrossProtectionScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final List<Application> _installedApps = [];
  final Map<String, bool> _lockedApps = {};
  bool _isLoadingApps = false;
  String _searchQuery = '';

  bool _isAntivirusEnabled = true;
  bool _isNetworkProtectionEnabled = false;
  bool _isAppLockEnabled = false;
  bool _isPrivacyProtectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLockedApps();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    setState(() => _isLoadingApps = true);
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
      );
      setState(() {
        _installedApps.clear();
        _installedApps.addAll(apps);
        _isLoadingApps = false;
      });
    } catch (e) {
      setState(() => _isLoadingApps = false);
      _showMessageDialog("Error", "Failed to load installed apps: $e");
    }
  }

  Future<void> _loadLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedAppsJson = prefs.getString('locked_apps');
    if (lockedAppsJson != null) {
      setState(() {
        _lockedApps.addAll(Map<String, bool>.from(json.decode(lockedAppsJson)));
      });
    }
  }

  Future<void> _saveLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locked_apps', json.encode(_lockedApps));
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAppLock(String packageName, bool value) async {
    if (value) {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to lock this app',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (!authenticated) return;
    }

    setState(() {
      _lockedApps[packageName] = value;
    });
    await _saveLockedApps();
  }

  void _toggleProtection(String protectionType) async {
    if (protectionType == 'applock') {
      await _authenticateAndToggleAppLock();
      return;
    }

    setState(() {
      switch (protectionType) {
        case 'antivirus':
          _isAntivirusEnabled = !_isAntivirusEnabled;
          break;
        case 'network':
          _isNetworkProtectionEnabled = !_isNetworkProtectionEnabled;
          break;
        case 'privacy':
          _isPrivacyProtectionEnabled = !_isPrivacyProtectionEnabled;
          break;
      }
    });
  }

  Future<void> _authenticateAndToggleAppLock() async {
    try {
      final bool canAuthenticate = await auth.canCheckBiometrics ||
          await auth.isDeviceSupported();

      if (!canAuthenticate) {
        _showMessageDialog(
          "Not Supported",
          "No authentication methods available on this device.",
        );
        return;
      }

      final bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to ${_isAppLockEnabled ? 'disable' : 'enable'} App Lock',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        setState(() => _isAppLockEnabled = !_isAppLockEnabled);
        _showMessageDialog(
          'Success',
          'App Lock has been ${_isAppLockEnabled ? 'enabled' : 'disabled'}.',
        );
      }
    } on PlatformException catch (e) {
      _showMessageDialog('Error', 'Authentication failed: ${e.message}');
    }
  }

  List<Application> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;
    return _installedApps.where((app) =>
        app.appName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF08223A),
          title: const Text(
            "Smart Protection",
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Protection Features'),
              Tab(text: 'App Lock Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProtectionFeaturesTab(),
            _buildAppLockSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectionFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),
          const Text(
            "Smart Protection Features",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08223A),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              ProtectionCard(
                title: "Antivirus Protection",
                description: "Protect your device from viruses and malware.",
                isEnabled: _isAntivirusEnabled,
                onToggle: () => _toggleProtection('antivirus'),
              ),
              ProtectionCard(
                title: "Network Protection",
                description: "Prevent malicious connections and monitor your network.",
                isEnabled: _isNetworkProtectionEnabled,
                onToggle: () => _toggleProtection('network'),
              ),
              ProtectionCard(
                title: "App Lock",
                description: "Lock apps with device authentication.",
                isEnabled: _isAppLockEnabled,
                onToggle: () => _toggleProtection('applock'),
              ),
              ProtectionCard(
                title: "Privacy Protection",
                description: "Ensure your privacy is protected with data encryption.",
                isEnabled: _isPrivacyProtectionEnabled,
                onToggle: () => _toggleProtection('privacy'),
              ),
            ],
          ),
          const SizedBox(height: 02),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Your smart protection settings are synced across all platforms.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppLockSettingsTab() {
    if (!_isAppLockEnabled) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                "App Lock is disabled",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Enable App Lock feature to manage app locking",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _toggleProtection('applock'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Text("Enable App Lock"),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    if (_isLoadingApps) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search apps...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: _filteredApps.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "No apps found for '$_searchQuery'",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _filteredApps.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final app = _filteredApps[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: app is ApplicationWithIcon
                    ? CircleAvatar(
                  backgroundImage: MemoryImage(app.icon),
                  backgroundColor: Colors.transparent,
                )
                    : const CircleAvatar(
                  child: Icon(Icons.android),
                ),
                title: Text(
                  app.appName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                trailing: Switch(
                  value: _lockedApps[app.packageName] ?? false,
                  onChanged: (value) => _toggleAppLock(app.packageName, value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF08223A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Welcome! Secure your device using smart cross-platform features below.',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

class ProtectionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isEnabled;
  final VoidCallback onToggle;

  const ProtectionCard({
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onToggle(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                onChanged: (_) => onToggle(),
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}