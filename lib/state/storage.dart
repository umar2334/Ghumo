import 'package:shared_preferences/shared_preferences.dart';

/// Minimal persistence interface so the store can be tested without plugins.
abstract class AppStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPrefsStorage implements AppStorage {
  static const _key = 'ghumo_state_v1';

  @override
  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String value) async {
    await (await SharedPreferences.getInstance()).setString(_key, value);
  }
}

class MemoryStorage implements AppStorage {
  MemoryStorage([this.value]);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String newValue) async => value = newValue;
}
