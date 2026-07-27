import 'dart:async';
import 'dart:typed_data';

import 'package:super_clipboard/super_clipboard.dart';

class ClipboardImage {
  const ClipboardImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Reads a native desktop clipboard image. macOS and Windows clipboard images
/// are transparently exposed as PNG by super_clipboard.
Future<ClipboardImage?> waitForClipboardImage() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) return null;
  final reader = await clipboard.read();
  for (final candidate in const [
    (Formats.png, 'png'),
    (Formats.jpeg, 'jpg'),
    (Formats.webp, 'webp'),
    (Formats.gif, 'gif'),
  ]) {
    if (!reader.canProvide(candidate.$1)) continue;
    final result = await _readImage(reader, candidate.$1, candidate.$2);
    if (result != null) return result;
  }
  return null;
}

Future<ClipboardImage?> _readImage(
  ClipboardReader reader,
  FileFormat format,
  String extension,
) async {
  final completer = Completer<ClipboardImage?>();
  final progress = reader.getFile(format, (file) async {
    try {
      completer.complete(
        ClipboardImage(bytes: await file.readAll(), extension: extension),
      );
    } catch (_) {
      completer.complete(null);
    }
  }, onError: (_) => completer.complete(null));
  if (progress == null) return null;
  return completer.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => null,
  );
}
