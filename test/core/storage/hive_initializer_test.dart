import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/storage/hive_box_names.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';

void main() {
  test('HiveInitializer opens all required structured boxes', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('senior-companion-hive');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async {
        Hive.init(tempDir.path);
      },
    );

    await initializer.initialize();

    for (final boxName in HiveBoxNames.all) {
      expect(Hive.isBoxOpen(boxName), isTrue);
    }

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
