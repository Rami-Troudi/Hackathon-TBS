import 'package:hive_flutter/hive_flutter.dart';
import 'package:senior_companion/core/storage/hive_box_names.dart';

class HiveInitializer {
  HiveInitializer({
    HiveInterface? hive,
    Future<void> Function()? initFunction,
  })  : _hive = hive ?? Hive,
        _initFunction = initFunction ?? Hive.initFlutter;

  final HiveInterface _hive;
  final Future<void> Function() _initFunction;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initFunction();
    await _openBoxes();
    _isInitialized = true;
  }

  Future<void> _openBoxes() async {
    for (final boxName in HiveBoxNames.all) {
      if (!_hive.isBoxOpen(boxName)) {
        await _hive.openBox<Map>(boxName);
      }
    }
  }

  Future<void> clearStructuredBoxes() async {
    await _openBoxes();
    for (final boxName in HiveBoxNames.all) {
      await _hive.box<Map>(boxName).clear();
    }
  }

  Box<Map> box(String boxName) => _hive.box<Map>(boxName);
}
