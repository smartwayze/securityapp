import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

class DataEncryptionscreen {
  final String _password = 'your_secure_password';
  final String _salt = 'your_secure_salt';
  late encrypt.Key _key;
  late encrypt.IV _iv;
  late encrypt.Encrypter _encrypter;

  DataEncryptionscreen() {
    _initialize();
  }

  void _initialize() {
    final keyDerivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(utf8.encode(_salt), 10000, 32));
    final derivedKey = keyDerivator.process(utf8.encode(_password));

    _key = encrypt.Key(Uint8List.fromList(derivedKey));
    _iv = encrypt.IV.fromLength(16);

    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedText) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
    return decrypted;
  }

  bool detectAbnormalActivity() {
    return false;
  }

  void applyAppLock() {
    if (detectAbnormalActivity()) {
      print('Abnormal activity detected. App lock applied.');
    }
  }
}


class EncryptionScreen extends StatefulWidget {
  @override
  _EncryptionScreenState createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  final DataEncryptionscreen _dataEncryption = DataEncryptionscreen();
  bool isEncrypting = false;
  String _encryptedText = '';
  String _decryptedText = '';
  final TextEditingController _inputController = TextEditingController();

  void _startEncryption() {
    setState(() {
      isEncrypting = true;
      _encryptedText = '';
      _decryptedText = '';
    });

    Timer(Duration(seconds: 2), () {
      final plainText = _inputController.text;
      setState(() {
        _encryptedText = _dataEncryption.encryptData(plainText);
        isEncrypting = false;
      });
    });
  }

  void _startDecryption() {
    setState(() {
      isEncrypting = true;
    });

    Timer(Duration(seconds: 2), () {
      setState(() {
        _decryptedText = _dataEncryption.decryptData(_encryptedText);
        isEncrypting = false;
      });
    });
  }

  Widget _buildEncryptButton() {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: isEncrypting ? null : _startEncryption,
        icon: Icon(Icons.lock),
        label: Text("Encrypt Data"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDecryptButton() {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: isEncrypting || _encryptedText.isEmpty ? null : _startDecryption,
        icon: Icon(Icons.lock_open),
        label: Text("Decrypt Data"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_encryptedText.isEmpty && _decryptedText.isEmpty && !isEncrypting) {
      return Text(
        "No data encrypted or decrypted yet.\nEnter data and tap 'Encrypt Data' to start.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    return Column(
      children: [
        if (_encryptedText.isNotEmpty)
          Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.lock, color: Colors.teal),
              title: Text("Encrypted Text"),
              subtitle: Text(_encryptedText),
            ),
          ),
        if (_decryptedText.isNotEmpty)
          Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.lock_open, color: Colors.teal),
              title: Text("Decrypted Text"),
              subtitle: Text(_decryptedText),
            ),
          ),
        if (isEncrypting)
          Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Processing..."),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Goes back to previous screen
          },
        ),
        title: Text(
          "Data Encryption & Decryption",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0A223D),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      backgroundColor: Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF0A223D),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.security, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text(
                    "AI-Powered Data Encryption",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Encrypt sensitive data and decrypt it securely.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      labelText: "Enter Data",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      _buildEncryptButton(),
                      SizedBox(width: 10),
                      _buildDecryptButton(),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildResults(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
