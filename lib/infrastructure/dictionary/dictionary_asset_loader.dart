import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DictionaryAssetLoader {
  const DictionaryAssetLoader({
    this.assetPath = 'assets/dictionaries/dictionary_v1.db.gz',
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
    final fingerprintFile = File(
      p.join(dictionaryDirectory.path, 'dictionary_v1.db.asset-size'),
    );

    await dictionaryDirectory.create(recursive: true);

    final assetData = await rootBundle.load(assetPath);
    final compressedBytes = assetData.buffer.asUint8List();
    final assetFingerprint = compressedBytes.length.toString();

    if (await targetFile.exists() &&
        await fingerprintFile.exists() &&
        await fingerprintFile.readAsString() == assetFingerprint) {
      return targetFile;
    }

    final bytes = GZipCodec().decode(compressedBytes);
    await targetFile.writeAsBytes(bytes, flush: true);
    await fingerprintFile.writeAsString(assetFingerprint, flush: true);

    return targetFile;
  }
}
