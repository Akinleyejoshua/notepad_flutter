import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A premium rich text formatting toolbar for the WebView editor.
/// Communicates with the contenteditable div via JavaScript commands.
class EditorToolbar extends StatefulWidget {
  final WebViewController webController;
  final VoidCallback onToggleRecording;
  final bool isRecording;

  const EditorToolbar({
    super.key,
    required this.webController,
    required this.onToggleRecording,
    required this.isRecording,
  });

  @override
  State<EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar> {
  final ImagePicker _imagePicker = ImagePicker();

  // ── Text Formatting Commands ──

  void _execCommand(String command, [String? value]) {
    final valueArg = value != null ? "'$value'" : 'null';
    widget.webController.runJavaScript(
      "document.execCommand('$command', false, $valueArg); true;",
    );
  }

  void _formatBold() => _execCommand('bold');
  void _formatItalic() => _execCommand('italic');
  void _formatUnderline() => _execCommand('underline');
  void _formatStrikethrough() => _execCommand('strikeThrough');
  void _formatBulletList() => _execCommand('insertUnorderedList');
  void _formatNumberedList() => _execCommand('insertOrderedList');
  void _formatAlignLeft() => _execCommand('justifyLeft');
  void _formatAlignCenter() => _execCommand('justifyCenter');
  void _formatAlignRight() => _execCommand('justifyRight');
  void _formatHeading(String tag) => _execCommand('formatBlock', tag);
  void _formatQuote() => _execCommand('formatBlock', 'blockquote');
  void _undoAction() => _execCommand('undo');
  void _redoAction() => _execCommand('redo');

  // ── Media Import ──

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final base64 = base64Encode(bytes);
      final mimeType = picked.mimeType ?? 'image/jpeg';

      final imgHtml = '''
        <div class="media-container" contenteditable="false">
          <img src="data:$mimeType;base64,$base64" style="max-width:100%;border-radius:8px;" />
          <button class="asset-delete-btn" onclick="this.parentElement.remove();">×</button>
        </div><br>
      ''';

      final escapedHtml = jsonEncode(imgHtml);
      await widget.webController.runJavaScript(
        'window.insertMediaToDOM($escapedHtml); true;',
      );
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final base64 = base64Encode(bytes);
      final mimeType = picked.mimeType ?? 'video/mp4';

      final videoHtml = '''
        <div class="media-container" contenteditable="false">
          <video src="data:$mimeType;base64,$base64" controls style="max-width:100%;border-radius:8px;"></video>
          <button class="asset-delete-btn" onclick="this.parentElement.remove();">×</button>
        </div><br>
      ''';

      final escapedHtml = jsonEncode(videoHtml);
      await widget.webController.runJavaScript(
        'window.insertMediaToDOM($escapedHtml); true;',
      );
    } catch (e) {
      debugPrint('Video pick error: $e');
    }
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result == null || result.files.single.path == null) return;

      final bytes = await File(result.files.single.path!).readAsBytes();
      final base64 = base64Encode(bytes);

      final audioHtml = '''
        <div class="media-container" contenteditable="false">
          <audio src="data:audio/mpeg;base64,$base64" controls style="width:100%;"></audio>
          <button class="asset-delete-btn" onclick="this.parentElement.remove();">×</button>
        </div><br>
      ''';

      final escapedHtml = jsonEncode(audioHtml);
      await widget.webController.runJavaScript(
        'window.insertMediaToDOM($escapedHtml); true;',
      );
    } catch (e) {
      debugPrint('Audio pick error: $e');
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MediaPickerSheet(
        onCameraImage: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGalleryImage: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
        onGalleryVideo: () {
          Navigator.pop(context);
          _pickVideo();
        },
        onAudioFile: () {
          Navigator.pop(context);
          _pickAudio();
        },
        onRecordAudio: () {
          Navigator.pop(context);
          widget.onToggleRecording();
        },
        isRecording: widget.isRecording,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Undo / Redo
            _ToolbarButton(icon: Icons.undo_rounded, onTap: _undoAction, tooltip: 'Undo'),
            _ToolbarButton(icon: Icons.redo_rounded, onTap: _redoAction, tooltip: 'Redo'),
            _divider(),

            // Text formatting
            _ToolbarButton(icon: Icons.format_bold_rounded, onTap: _formatBold, tooltip: 'Bold'),
            _ToolbarButton(icon: Icons.format_italic_rounded, onTap: _formatItalic, tooltip: 'Italic'),
            _ToolbarButton(icon: Icons.format_underline_rounded, onTap: _formatUnderline, tooltip: 'Underline'),
            _ToolbarButton(icon: Icons.strikethrough_s_rounded, onTap: _formatStrikethrough, tooltip: 'Strikethrough'),
            _divider(),

            // Headings
            _ToolbarTextButton(label: 'H1', onTap: () => _formatHeading('h1')),
            _ToolbarTextButton(label: 'H2', onTap: () => _formatHeading('h2')),
            _ToolbarTextButton(label: 'H3', onTap: () => _formatHeading('h3')),
            _ToolbarTextButton(label: '¶', onTap: () => _formatHeading('p')),
            _divider(),

            // Lists
            _ToolbarButton(icon: Icons.format_list_bulleted_rounded, onTap: _formatBulletList, tooltip: 'Bullet List'),
            _ToolbarButton(icon: Icons.format_list_numbered_rounded, onTap: _formatNumberedList, tooltip: 'Numbered List'),
            _ToolbarButton(icon: Icons.format_quote_rounded, onTap: _formatQuote, tooltip: 'Quote'),
            _divider(),

            // Alignment
            _ToolbarButton(icon: Icons.format_align_left_rounded, onTap: _formatAlignLeft, tooltip: 'Align Left'),
            _ToolbarButton(icon: Icons.format_align_center_rounded, onTap: _formatAlignCenter, tooltip: 'Center'),
            _ToolbarButton(icon: Icons.format_align_right_rounded, onTap: _formatAlignRight, tooltip: 'Align Right'),
            _divider(),

            // Media
            _ToolbarButton(
              icon: Icons.attach_file_rounded,
              onTap: _showMediaPicker,
              tooltip: 'Insert Media',
              isAccent: true,
            ),
            _ToolbarButton(
              icon: widget.isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
              onTap: widget.onToggleRecording,
              tooltip: widget.isRecording ? 'Stop Recording' : 'Record Audio',
              isAccent: widget.isRecording,
              accentColor: widget.isRecording ? const Color(0xFFEF4444) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFE5E7EB),
    );
  }
}

// ─── Toolbar Button ──────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isAccent;
  final Color? accentColor;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isAccent = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? (isAccent ? const Color(0xFF111111) : const Color(0xFF6B7280));

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isAccent
                ? (accentColor ?? const Color(0xFF111111)).withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ─── Toolbar Text Button (for headings) ──────────────────────────────────────

class _ToolbarTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ToolbarTextButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            fontFamily: 'Bricolage',
          ),
        ),
      ),
    );
  }
}

// ─── Media Picker Bottom Sheet ───────────────────────────────────────────────

class _MediaPickerSheet extends StatelessWidget {
  final VoidCallback onCameraImage;
  final VoidCallback onGalleryImage;
  final VoidCallback onGalleryVideo;
  final VoidCallback onAudioFile;
  final VoidCallback onRecordAudio;
  final bool isRecording;

  const _MediaPickerSheet({
    required this.onCameraImage,
    required this.onGalleryImage,
    required this.onGalleryVideo,
    required this.onAudioFile,
    required this.onRecordAudio,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded, size: 22, color: Color(0xFF111111)),
                SizedBox(width: 10),
                Text(
                  'Insert Media',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                    fontFamily: 'Bricolage',
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Options
          _MediaOption(
            icon: Icons.camera_alt_rounded,
            label: 'Take Photo',
            subtitle: 'Capture with camera',
            color: const Color(0xFF3B82F6),
            onTap: onCameraImage,
          ),
          _MediaOption(
            icon: Icons.photo_library_rounded,
            label: 'Photo from Gallery',
            subtitle: 'Pick an existing image',
            color: const Color(0xFF10B981),
            onTap: onGalleryImage,
          ),
          _MediaOption(
            icon: Icons.videocam_rounded,
            label: 'Video from Gallery',
            subtitle: 'Pick an existing video',
            color: const Color(0xFF8B5CF6),
            onTap: onGalleryVideo,
          ),
          _MediaOption(
            icon: Icons.audio_file_rounded,
            label: 'Audio File',
            subtitle: 'Import an audio file',
            color: const Color(0xFFF59E0B),
            onTap: onAudioFile,
          ),
          _MediaOption(
            icon: isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
            label: isRecording ? 'Stop Recording' : 'Record Audio',
            subtitle: isRecording ? 'Stop the current recording' : 'Record a voice memo',
            color: const Color(0xFFEF4444),
            onTap: onRecordAudio,
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                        fontFamily: 'Bricolage',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Bricolage',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}
