import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../providers/ui_provider.dart';
import '../widgets/custom_modal.dart';
import '../widgets/webview_editor.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  WebViewController? _webController;
  String _htmlContent = '';
  List<String> _mediaPaths = [];
  bool _hasChanges = false;
  bool get isEditMode => widget.note != null;

  // Recording state
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _currentRecordingPath;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonScale;

  String _decodeHtmlEscapes(String input) {
    var text = input;
    // Decode Unicode HTML escapes (e.g. \u003c -> <, \u003e -> >)
    text = text.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
    );
    return text;
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note?.title ?? '';
    _htmlContent = _decodeHtmlEscapes(widget.note?.content ?? '');
    _mediaPaths = List<String>.from(widget.note?.mediaPaths ?? []);
    _titleController.addListener(_onContentChanged);

    // Pulse animation for recording indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Save button scale animation
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _saveButtonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.easeInOut),
    );
  }

  void _onContentChanged() {
    final originalTitle = widget.note?.title ?? '';
    final originalContent = widget.note?.content ?? '';
    final changed =
        _titleController.text != originalTitle ||
        _htmlContent != originalContent ||
        _mediaPaths.length != (widget.note?.mediaPaths.length ?? 0);
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onContentChanged);
    _titleController.dispose();
    _titleFocusNode.dispose();
    _pulseController.dispose();
    _saveButtonController.dispose();
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await CustomConfirmDialog.show(
      context,
      title: 'Discard Changes?',
      message: 'You have unsaved changes. Are you sure you want to leave?',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep Editing',
      isDangerous: true,
      confirmIcon: Icons.delete_outline,
    );
    return result == true;
  }

  // ── Media Picking ──

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      _insertImageIntoEditor(picked.path, picked.mimeType ?? 'image/jpeg');
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
      _insertVideoIntoEditor(picked.path, picked.mimeType ?? 'video/mp4');
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
      _insertAudioIntoEditor(result.files.single.path!);
    } catch (e) {
      debugPrint('Audio pick error: $e');
    }
  }

  Future<void> _insertImageIntoEditor(String path, String mimeType) async {
    final savedPath = await _saveMediaToAppDirectory(path);
    final fileUrl = Uri.file(savedPath).toString();
    final imgHtml =
        '''
      <div class="media-container" contenteditable="false">
        <img src="$fileUrl" style="max-width:100%;border-radius:12px;" />
        <button class="asset-delete-btn" onclick="this.parentElement.remove();">×</button>
      </div><br>
    ''';
    setState(() => _mediaPaths.add(savedPath));
    _onContentChanged();
    _insertHtmlIntoEditor(imgHtml);
  }

  Future<void> _insertVideoIntoEditor(String path, String mimeType) async {
    final savedPath = await _saveMediaToAppDirectory(path);
    final fileUrl = Uri.file(savedPath).toString();
    final videoHtml =
        '''
      <div class="media-container" contenteditable="false">
        <video src="$fileUrl" controls style="max-width:100%;border-radius:12px;">
          <button class="asset-delete-btn" onclick="this.parentElement.remove();">×</button>
        </video>
      </div><br>
    ''';
    setState(() => _mediaPaths.add(savedPath));
    _onContentChanged();
    _insertHtmlIntoEditor(videoHtml);
  }

  Future<void> _insertAudioIntoEditor(String path) async {
    final savedPath = await _saveMediaToAppDirectory(path);
    final fileUrl = Uri.file(savedPath).toString();
    final audioHtml =
        '''
      <div class="audio-recording" contenteditable="false">
        <audio src="$fileUrl" controls style="width:100%;">
          <button class="asset-delete-btn" onclick="this.parentElement.remove();" style="position:relative;top:auto;right:auto;width:24px;height:24px;font-size:14px;flex-shrink:0;">×</button>
        </audio>
      </div><br>
    ''';
    setState(() => _mediaPaths.add(savedPath));
    _onContentChanged();
    _insertHtmlIntoEditor(audioHtml);
  }

  void _insertHtmlIntoEditor(String html) {
    if (_webController == null) return;
    final escapedHtml = jsonEncode(html);
    _webController!.runJavaScript(
      'window.insertMediaToDOM($escapedHtml); true;',
    );
  }

  // ── Audio Recording ──

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Check permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        Provider.of<UiProvider>(context, listen: false).showToast(
          'Microphone permission is required to record audio',
          type: ToastType.warning,
        );
      }
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${dir.path}/recording_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _pulseController.repeat(reverse: true);

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      debugPrint('Recording start error: $e');
      if (mounted) {
        Provider.of<UiProvider>(
          context,
          listen: false,
        ).showToast('Failed to start recording', type: ToastType.error);
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _recordingTimer?.cancel();
      _pulseController.stop();
      _pulseController.reset();

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      if (path != null && path.isNotEmpty) {
        await _insertAudioIntoEditor(path);
        if (mounted) {
          Provider.of<UiProvider>(
            context,
            listen: false,
          ).showToast('Recording saved & inserted', type: ToastType.success);
        }
      }
    } catch (e) {
      debugPrint('Recording stop error: $e');
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ── Formatting Commands ──

  void _execCommand(String command, [String? value]) {
    if (_webController == null) return;
    final valueArg = value != null ? "'$value'" : 'null';
    _webController!.runJavaScript(
      "document.execCommand('$command', false, $valueArg); true;",
    );
  }

  // ── Save ──

  Future<void> _saveDocument() async {
    _saveButtonController.forward().then(
      (_) => _saveButtonController.reverse(),
    );

    // Get latest content from WebView
    if (_webController != null) {
      try {
        final result = await _webController!.runJavaScriptReturningResult(
          'window.getEditorContent()',
        );
        if (result is String) {
          _htmlContent = result;
          // Remove surrounding quotes if present
          if (_htmlContent.startsWith('"') && _htmlContent.endsWith('"')) {
            _htmlContent = _htmlContent.substring(1, _htmlContent.length - 1);
            // Unescape
            _htmlContent = _htmlContent
                .replaceAll('\\"', '"')
                .replaceAll('\\n', '\n')
                .replaceAll('\\/', '/');
          }
        }
      } catch (e) {
        debugPrint('Error getting editor content: $e');
      }
    }

    if (!mounted) return;

    final ui = Provider.of<UiProvider>(context, listen: false);

    if (_titleController.text.trim().isEmpty) {
      if (mounted) {
        ui.showToast(
          'Please enter some content for the note',
          type: ToastType.warning,
        );
      }
      return;
    }

    ui.showLoading(message: 'Saving note...');

    try {
      if (!mounted) return;
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final currentTitle = _titleController.text.trim();
      if (isEditMode) {
        final updatedNote = widget.note!.copyWith(
          title: currentTitle,
          content: _htmlContent,
          mediaPaths: _mediaPaths,
          lastEdited: DateTime.now(),
        );
        notesProvider.addOrUpdateNote(updatedNote);
      } else {
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: currentTitle,
          content: _htmlContent,
          mediaPaths: _mediaPaths,
          lastEdited: DateTime.now(),
        );
        notesProvider.addOrUpdateNote(newNote);
      }
      ui.hideLoading();
      ui.showToast(
        isEditMode ? 'Note updated successfully' : 'Note created successfully',
        type: ToastType.success,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ui.hideLoading();
      ui.showToast('Failed to save note', type: ToastType.error);
    }
  }

  // ── Media Picker Bottom Sheet ──

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PremiumMediaPickerSheet(
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
          _toggleRecording();
        },
        isRecording: _isRecording,
      ),
    );
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFB),
        body: Column(
          children: [
            // ── Premium Header ──
            _buildHeader(topPadding),

            // ── Editor Area ──
            Expanded(
              child: WebViewEditor(
                initialContent: _htmlContent,
                onContentChanged: (content) {
                  _htmlContent = content;
                  _onContentChanged();
                },
                onControllerReady: (controller) {
                  setState(() => _webController = controller);
                },
              ),
            ),

            // ── Recording Indicator ──
            if (_isRecording) _buildRecordingBar(),

            // ── Formatting Toolbar ──
            _buildFormattingToolbar(bottomPadding),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Back + Actions
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop && mounted) Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Mode badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEditMode
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEditMode ? 'Editing' : 'New Note',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEditMode
                        ? const Color(0xFF92400E)
                        : const Color(0xFF166534),
                    fontFamily: 'Bricolage',
                  ),
                ),
              ),

              const Spacer(),

              // Save button
              ScaleTransition(
                scale: _saveButtonScale,
                child: GestureDetector(
                  onTap: _saveDocument,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF111827), Color(0xFF1F2937)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF111827,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Bricolage',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title input
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.2,
              fontFamily: 'Bricolage',
            ),
            decoration: const InputDecoration(
              hintText: 'Untitled Note',
              hintStyle: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD1D5DB),
                letterSpacing: -0.5,
                fontFamily: 'Bricolage',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),

          const SizedBox(height: 6),

          // Metadata row
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                _getDateLabel(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontFamily: 'Bricolage',
                ),
              ),
              if (_mediaPaths.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.attach_file_rounded,
                  size: 13,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 3),
                Text(
                  '${_mediaPaths.length} attachment${_mediaPaths.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontFamily: 'Bricolage',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getDateLabel() {
    final now = DateTime.now();
    final date = widget.note?.lastEdited ?? now;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Recording Bar ──
  Widget _buildRecordingBar() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFEE2E2), Color(0xFFFECACA)],
            ),
          ),
          child: Row(
            children: [
              // Pulsing red dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFEF4444),
                    const Color(0xFFDC2626),
                    _pulseAnimation.value,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFEF4444,
                      ).withValues(alpha: _pulseAnimation.value * 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recording',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626).withValues(alpha: 0.9),
                  fontFamily: 'Bricolage',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                  fontFamily: 'Bricolage',
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Stop',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Bricolage',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Formatting Toolbar ──
  Widget _buildFormattingToolbar(double bottomPadding) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrollable formatting toolbar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Undo / Redo
                _ToolbarBtn(
                  icon: Icons.undo_rounded,
                  onTap: () => _execCommand('undo'),
                  tooltip: 'Undo',
                ),
                _ToolbarBtn(
                  icon: Icons.redo_rounded,
                  onTap: () => _execCommand('redo'),
                  tooltip: 'Redo',
                ),
                _toolbarDivider(),

                // Text formatting
                _ToolbarBtn(
                  icon: Icons.format_bold_rounded,
                  onTap: () => _execCommand('bold'),
                  tooltip: 'Bold',
                ),
                _ToolbarBtn(
                  icon: Icons.format_italic_rounded,
                  onTap: () => _execCommand('italic'),
                  tooltip: 'Italic',
                ),
                _ToolbarBtn(
                  icon: Icons.format_underlined_rounded,
                  onTap: () => _execCommand('underline'),
                  tooltip: 'Underline',
                ),
                _ToolbarBtn(
                  icon: Icons.strikethrough_s_rounded,
                  onTap: () => _execCommand('strikeThrough'),
                  tooltip: 'Strikethrough',
                ),
                _toolbarDivider(),

                // Headings
                _HeadingBtn(
                  label: 'H1',
                  onTap: () => _execCommand('formatBlock', 'h1'),
                ),
                _HeadingBtn(
                  label: 'H2',
                  onTap: () => _execCommand('formatBlock', 'h2'),
                ),
                _HeadingBtn(
                  label: 'H3',
                  onTap: () => _execCommand('formatBlock', 'h3'),
                ),
                _HeadingBtn(
                  label: '¶',
                  onTap: () => _execCommand('formatBlock', 'p'),
                ),
                _toolbarDivider(),

                // Lists & Quote
                _ToolbarBtn(
                  icon: Icons.format_list_bulleted_rounded,
                  onTap: () => _execCommand('insertUnorderedList'),
                  tooltip: 'Bullet List',
                ),
                _ToolbarBtn(
                  icon: Icons.format_list_numbered_rounded,
                  onTap: () => _execCommand('insertOrderedList'),
                  tooltip: 'Numbered List',
                ),
                _ToolbarBtn(
                  icon: Icons.format_quote_rounded,
                  onTap: () => _execCommand('formatBlock', 'blockquote'),
                  tooltip: 'Quote',
                ),
                _toolbarDivider(),

                // Alignment
                _ToolbarBtn(
                  icon: Icons.format_align_left_rounded,
                  onTap: () => _execCommand('justifyLeft'),
                  tooltip: 'Align Left',
                ),
                _ToolbarBtn(
                  icon: Icons.format_align_center_rounded,
                  onTap: () => _execCommand('justifyCenter'),
                  tooltip: 'Center',
                ),
                _ToolbarBtn(
                  icon: Icons.format_align_right_rounded,
                  onTap: () => _execCommand('justifyRight'),
                  tooltip: 'Align Right',
                ),
                _toolbarDivider(),

                // Media attach
                _ToolbarBtn(
                  icon: Icons.attach_file_rounded,
                  onTap: _showMediaPicker,
                  tooltip: 'Insert Media',
                  isAccent: true,
                  accentColor: const Color(0xFF6366F1),
                ),

                // Record
                _ToolbarBtn(
                  icon: _isRecording
                      ? Icons.stop_circle_rounded
                      : Icons.mic_rounded,
                  onTap: _toggleRecording,
                  tooltip: _isRecording ? 'Stop Recording' : 'Record Audio',
                  isAccent: true,
                  accentColor: _isRecording
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),

          // Bottom safe area padding
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFE5E7EB),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Toolbar Widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isAccent;
  final Color? accentColor;

  const _ToolbarBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isAccent = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        accentColor ??
        (isAccent ? const Color(0xFF111111) : const Color(0xFF6B7280));
    final bgColor = isAccent
        ? (accentColor ?? const Color(0xFF111111)).withValues(alpha: 0.08)
        : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _HeadingBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeadingBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
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

// ═══════════════════════════════════════════════════════════════════════════════
// Media Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _PremiumMediaPickerSheet extends StatelessWidget {
  final VoidCallback onCameraImage;
  final VoidCallback onGalleryImage;
  final VoidCallback onGalleryVideo;
  final VoidCallback onAudioFile;
  final VoidCallback onRecordAudio;
  final bool isRecording;

  const _PremiumMediaPickerSheet({
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insert Media',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                        fontFamily: 'Bricolage',
                      ),
                    ),
                    Text(
                      'Add images, videos, or audio to your note',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Bricolage',
                      ),
                    ),
                  ],
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
            subtitle: isRecording
                ? 'Stop the current recording'
                : 'Record a voice memo',
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
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String> _saveMediaToAppDirectory(String sourcePath) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    final extension = sourcePath.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp.$extension';
    final destPath = '${mediaDir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return destPath;
  } catch (e) {
    debugPrint('Error saving media to app directory: $e');
    return sourcePath; // Fallback to original path
  }
}
