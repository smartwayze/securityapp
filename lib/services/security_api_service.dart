import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SecurityApiService {
  static const String _nvdBaseUrl = "https://services.nvd.nist.gov/rest/json/cves/1.0";
  static const String _sslLabsUrl = "https://api.ssllabs.com/api/v3/analyze";
  static const String _snykBaseUrl = "https://snyk.io/api/v1";

  // Add your API keys here
  static const String snykApiKey = "a710b57b-7d7e-48ec-a128-89c47b95afe6";

  // SSL Labs API - Check SSL/TLS configuration
  static Future<Map<String, dynamic>> checkSSL(String domain) async {
    final response = await http.get(Uri.parse("$_sslLabsUrl?host=$domain"));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("SSL Labs API failed: ${response.statusCode}");
    }
  }

  // NVD API - Get vulnerabilities for a software/component
  static Future<List<dynamic>> getVulnerabilities(String keyword) async {
    final formattedKeyword = Uri.encodeComponent(keyword);
    final response = await http.get(Uri.parse("$_nvdBaseUrl?keyword=$formattedKeyword"));

    if (response.statusCode == 200) {
      return json.decode(response.body)['result']['CVE_Items'] ?? [];
    }
    return [];
  }

  // Snyk API - Check package vulnerabilities
  static Future<Map<String, dynamic>> checkPackage(String packageName, String version) async {
    final response = await http.get(
        Uri.parse("$_snykBaseUrl/package/$packageName/$version"),
        headers: {"Authorization": "token $snykApiKey"}
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  // Format date for NVD API
  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}