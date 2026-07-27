import 'dart:async';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../utils/clipboard_image.dart';

/// A single, keyboard-accessible image surface used by the menu editors.
///
/// A selected file stays local until the editor is saved. This prevents orphan
/// Storage objects when a staff member abandons an edit.
class MenuImagePicker extends StatefulWidget {
  const MenuImagePicker({
    required this.imageBytes,
    required this.imageUrl,
    required this.onImageSelected,
    required this.onUrlPasted,
    this.height = 236,
    this.compactCopy = false,
    super.key,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final void Function(Uint8List bytes, String extension) onImageSelected;
  final ValueChanged<String> onUrlPasted;
  final double height;
  final bool compactCopy;

  @override
  State<MenuImagePicker> createState() => _MenuImagePickerState();
}

class _MenuImagePickerState extends State<MenuImagePicker> {
  final _focusNode = FocusNode();
  var _dragging = false;
  var _readingClipboard = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    widget.onImageSelected(
      file!.bytes!,
      _extension(file.extension ?? file.name),
    );
  }

  Future<void> _useDrop(List<DropItem> files) async {
    final file = files
        .where((item) => item.mimeType?.startsWith('image/') ?? false)
        .firstOrNull;
    if (file == null) return;
    widget.onImageSelected(await file.readAsBytes(), _extension(file.name));
  }

  Future<void> _paste() async {
    if (_readingClipboard) return;
    setState(() => _readingClipboard = true);
    try {
      final text = (await Clipboard.getData(
        Clipboard.kTextPlain,
      ))?.text?.trim();
      if (text != null && _isUrl(text)) {
        widget.onUrlPasted(text);
        return;
      }
      final image = await waitForClipboardImage();
      if (image != null) widget.onImageSelected(image.bytes, image.extension);
    } finally {
      if (mounted) setState(() => _readingClipboard = false);
    }
  }

  bool _isUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String _extension(String value) {
    final segments = value.toLowerCase().split('.');
    return segments.length > 1 ? segments.last : 'jpg';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageBytes != null || widget.imageUrl != null;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        unawaited(_useDrop(details.files));
      },
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyV &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            unawaited(_paste());
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Semantics(
          button: true,
          label:
              'Menu item image. Click to choose an image, or paste or drop one.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _focusNode.requestFocus();
              unawaited(_pickFile());
            },
            child: AnimatedContainer(
              duration: TavolaMotion.fast,
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _dragging
                    ? TavolaColors.accentLight
                    : TavolaColors.surfaceVariant,
                border: Border.all(
                  color: _dragging ? TavolaColors.accent : TavolaColors.border,
                  width: _dragging ? 2 : 1,
                ),
                borderRadius: TavolaRadius.medium,
              ),
              child: ClipRRect(
                borderRadius: TavolaRadius.medium,
                child: hasImage
                    ? _ImagePreview(
                        bytes: widget.imageBytes,
                        url: widget.imageUrl,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _readingClipboard
                                ? Icons.hourglass_top_rounded
                                : Icons.add_photo_alternate_outlined,
                            size: TavolaSize.iconLarge,
                            color: TavolaColors.accentDark,
                          ),
                          const SizedBox(height: TavolaSpace.sm),
                          Text(
                            _dragging
                                ? 'Drop image to upload'
                                : widget.compactCopy
                                ? 'Upload item photo'
                                : 'Click, drop, or paste an image',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: TavolaSpace.xxs),
                          Text(
                            widget.compactCopy
                                ? 'PNG or JPG up to 5 MB'
                                : 'Ctrl/Cmd+V also accepts an image URL',
                            style: const TextStyle(
                              color: TavolaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes, required this.url});

  final Uint8List? bytes;
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: BoxFit.contain);
    }
    return Image.network(
      url!,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          const Center(child: Text('Image URL could not be loaded')),
    );
  }
}
