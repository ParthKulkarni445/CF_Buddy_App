import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Save data
  static Future<void> saveData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Read data
  static Future<String?> readData(String key) async {
    return await _storage.read(key: key);
  }

  // Delete data
  static Future<void> deleteData(String key) async {
    await _storage.delete(key: key);
  }
}
