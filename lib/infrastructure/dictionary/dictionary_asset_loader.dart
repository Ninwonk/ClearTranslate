import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DictionaryAssetLoader {
  const DictionaryAssetLoader({
    this.assetPath = 'assets/dictionaries/dictionary_v1.db',
    Directory? supportDirectory,
  }) : _supportDirectory = supportDirectory;

  final String assetPath;
  final Directory? _supportDirectory;

  Future<File> ensureLoaded() async {
    final directory =
        _supportDirectory ?? await getApplicationSupportDirectory();
    final dictionaryDirectory =
        Directory(p.join(directory.path, 'dictionaries'));
    final targetFile =
        File(p.join(dictionaryDirectory.path, 'dictionary_v1.db'));

    await dictionaryDirectory.create(recursive: true);

    final assetData = await rootBundle.load(assetPath);
    final bytes = assetData.buffer.asUint8List();

    if (!await targetFile.exists() ||
        await targetFile.length() != bytes.length) {
      await targetFile.writeAsBytes(bytes, flush: true);
    }

    return targetFile;
  }
}
