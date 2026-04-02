// Stub implementation for mobile platforms when package:web is not available
abstract class Storage {
  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);

  static final Storage sessionStorage = _StorageStub();
}

class _StorageStub implements Storage {
  @override
  String? getItem(String key) => null;

  @override
  void setItem(String key, String value) {}

  @override
  void removeItem(String key) {}
}

class Window {
  final Storage sessionStorage = Storage.sessionStorage;
}

final Window window = Window();
