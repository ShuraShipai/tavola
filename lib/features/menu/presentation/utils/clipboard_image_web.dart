import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class ClipboardImage {
  const ClipboardImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Waits for the next browser paste event and returns its first image file.
/// The caller should prompt the user to press Ctrl/Cmd+V before invoking this.
Future<ClipboardImage?> waitForClipboardImage() async {
  final completer = Completer<ClipboardImage?>();
  late final web.EventListener listener;
  listener = ((web.Event event) {
    if (!event.isA<web.ClipboardEvent>()) return;
    final clipboardEvent = event as web.ClipboardEvent;
    final files = clipboardEvent.clipboardData?.files;
    if (files == null || files.length == 0) return;
    final file = files.item(0);
    if (file == null || !file.type.startsWith('image/')) return;
    event.preventDefault();
    web.document.removeEventListener('paste', listener);
    final reader = web.FileReader();
    reader.addEventListener(
      'loadend',
      ((web.Event _) {
        final result = reader.result;
        if (result == null || !result.isA<JSArrayBuffer>()) {
          completer.complete(null);
          return;
        }
        final bytes = Uint8List.view((result as JSArrayBuffer).toDart);
        completer.complete(
          ClipboardImage(
            bytes: bytes,
            extension: _extensionForMimeType(file.type),
          ),
        );
      }).toJS,
    );
    reader.readAsArrayBuffer(file);
  }).toJS;
  web.document.addEventListener('paste', listener);
  Timer(const Duration(seconds: 20), () {
    web.document.removeEventListener('paste', listener);
    if (!completer.isCompleted) completer.complete(null);
  });
  return completer.future;
}

String _extensionForMimeType(String mimeType) => switch (mimeType) {
  'image/png' => 'png',
  'image/webp' => 'webp',
  'image/gif' => 'gif',
  _ => 'jpg',
};
