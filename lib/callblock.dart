import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';

class CallBlockScreen extends StatefulWidget {
  @override
  _CallBlockScreenState createState() => _CallBlockScreenState();
}

class _CallBlockScreenState extends State<CallBlockScreen> {
  final List<String> knownSpamPatterns = ["+9112", "+1300", "+998", "unknown"];
  final List<CallLogEntry> blockedCalls = [];
  final List<CallLogEntry> allowedCalls = [];
  bool isLoading = false;

  bool isSpam(String? number) {
    if (number == null) return true;
    return knownSpamPatterns.any((pattern) => number.startsWith(pattern));
  }

  Future<void> _loadCallLogs() async {
    setState(() => isLoading = true);

    // Request permission
    var status = await Permission.phone.request();
    if (!status.isGranted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission denied to access call logs')),
      );
      return;
    }

    try {
      // Get call logs
      Iterable<CallLogEntry> entries = await CallLog.get();

      // Clear previous data
      blockedCalls.clear();
      allowedCalls.clear();

      // Process call logs
      for (var entry in entries) {
        if (isSpam(entry.number)) {
          blockedCalls.add(entry);
        } else {
          allowedCalls.add(entry);
        }
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading call logs: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildCallCard(CallLogEntry entry, bool isBlocked) {
    return Card(
      color: isBlocked ? Colors.red[50] : Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isBlocked ? Icons.block : Icons.call,
          color: isBlocked ? Colors.red : Colors.green,
        ),
        title: Text(entry.number ?? 'Unknown number'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isBlocked ? "Blocked (Spam Detected)" : "Allowed"),
            Text(_formatDate(DateTime.fromMillisecondsSinceEpoch(entry.timestamp!))),
            Text(_callTypeToString(entry.callType)),
          ],
        ),
        trailing: Icon(Icons.security),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  String _callTypeToString(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return 'Incoming';
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.missed:
        return 'Missed';
      case CallType.rejected:
        return 'Rejected';
      case CallType.blocked:
        return 'Blocked';
      default:
        return 'Unknown';
    }
  }
  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F6FA),
      appBar: AppBar(
        title: Text("Call Filter & Blocker"),
        backgroundColor: Color(0xFF08223A),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCallLogs,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else ...[
              Expanded(
                child: ListView(
                  children: [
                    Text("📛 Blocked Calls (${blockedCalls.length})",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ...blockedCalls.map((entry) => _buildCallCard(entry, true)).toList(),
                    SizedBox(height: 20),
                    Text("✅ Allowed Calls (${allowedCalls.length})",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ...allowedCalls.map((entry) => _buildCallCard(entry, false)).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}