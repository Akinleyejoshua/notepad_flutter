import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A premium WebView-based rich text editor using contenteditable HTML.
/// This replaces the broken plain-TextField approach with real formatting.
class WebViewEditor extends StatefulWidget {
  final String? initialContent;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<WebViewController>? onControllerReady;
  final ValueChanged<Map<String, bool>>? onFormatStateChanged;

  const WebViewEditor({
    super.key,
    this.initialContent,
    required this.onContentChanged,
    this.onControllerReady,
    this.onFormatStateChanged,
  });

  @override
  State<WebViewEditor> createState() => _WebViewEditorState();
}

class _WebViewEditorState extends State<WebViewEditor> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) {
          widget.onContentChanged(message.message);
        },
      )
      ..addJavaScriptChannel(
        'FormatState',
        onMessageReceived: (message) {
          if (widget.onFormatStateChanged == null) return;
          try {
            // Parse "bold:1,italic:0,..." format
            final Map<String, bool> states = {};
            for (final pair in message.message.split(',')) {
              final parts = pair.split(':');
              if (parts.length == 2) {
                states[parts[0]] = parts[1] == '1';
              }
            }
            widget.onFormatStateChanged!(states);
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            widget.onControllerReady?.call(_controller);

            // Set initial content if provided
            if (widget.initialContent != null &&
                widget.initialContent!.isNotEmpty) {
              _setContent(widget.initialContent!);
            }
          },
        ),
      )
      ..loadHtmlString(_buildEditorHtml());
  }

  void _setContent(String content) {
    // Use jsonEncode for safe JS string handling (handles base64, special chars, etc.)
    final jsonContent = jsonEncode(content);
    _controller.runJavaScript('window.setEditorContent($jsonContent);');
  }

  String _buildEditorHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    -webkit-tap-highlight-color: transparent;
  }

  html, body {
    height: 100%;
    width: 100%;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 1.7;
    color: #1F2937;
    background: transparent;
    -webkit-font-smoothing: antialiased;
    overflow-y: auto;
    -webkit-overflow-scrolling: touch;
  }

  #editor {
    min-height: 100%;
    padding: 20px !important;
    outline: none;
    word-wrap: break-word;
    overflow-wrap: break-word;
    white-space: pre-wrap;
  }

  #editor:empty:before {
    content: 'Start writing something amazing...';
    color: #CBD5E1;
    font-style: italic;
    pointer-events: none;
  }

  /* Heading styles */
  #editor h1 {
    font-size: 28px;
    font-weight: 800;
    color: #0F172A;
    margin: 20px 0 8px;
    line-height: 1.3;
    letter-spacing: -0.5px;
  }

  #editor h2 {
    font-size: 22px;
    font-weight: 700;
    color: #1E293B;
    margin: 16px 0 6px;
    line-height: 1.35;
    letter-spacing: -0.3px;
  }

  #editor h3 {
    font-size: 18px;
    font-weight: 600;
    color: #334155;
    margin: 12px 0 4px;
    line-height: 1.4;
  }

  /* Paragraph */
  #editor p {
    margin: 4px 0;
  }

  /* Lists */
  #editor ul, #editor ol {
    padding-left: 24px;
    margin: 8px 0;
  }

  #editor li {
    margin: 4px 0;
  }

  /* Blockquote */
  #editor blockquote {
    border-left: 4px solid #6366F1;
    padding: 8px 16px;
    margin: 12px 0;
    background: #F0F0FF;
    border-radius: 0 8px 8px 0;
    color: #4338CA;
    font-style: italic;
  }

  /* Media containers */
  .media-container {
    position: relative;
    display: flex;
    margin: 0px 0;
    max-width: 100%;
    height: max-content;
    min-height: max-content;
    border-radius: 12px;
    overflow: hidden !important;
    box-shadow: 0 2px 12px rgba(0,0,0,0.00);
  }

  .media-container img {
    max-width: 100%;
    height: auto;
    display: block;
    border-radius: 12px;
  }

  .media-container video {
    max-width: 100%;
    height: auto;
    display: block;
    border-radius: 12px;
  }

  .media-container audio {
    width: 100%;
    border-radius: 8px;
  }

  .asset-delete-btn {
    position: absolute;
    top: 8px;
    right: 8px;
    width: 28px;
    height: 28px;
    border-radius: 50%;
    background: rgba(239, 68, 68, 0.9);
    color: white;
    border: none;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    backdrop-filter: blur(4px);
    -webkit-backdrop-filter: blur(4px);
    z-index: 10;
  }

  .asset-delete-btn:active {
    transform: scale(0.9);
  }

  /* Audio recording embed */
  .audio-recording {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    margin: 8px 0;
    background: linear-gradient(135deg, #FEF3C7, #FDE68A);
    border-radius: 12px;
    border: 1px solid #F59E0B33;
  }

  .audio-recording audio {
    flex: 1;
    height: 36px;
  }

  /* Links */
  #editor a {
    color: #6366F1;
    text-decoration: underline;
  }

  /* Selection */
  ::selection {
    background: #C7D2FE;
    color: #1E1B4B;
  }
</style>
</head>
<body>
  <div id="editor" contenteditable="true"></div>

  <script>
    var editor = document.getElementById('editor');
    var debounceTimer = null;

    // Notify Flutter of content changes (debounced)
    editor.addEventListener('input', function() {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(function() {
        try {
          FlutterBridge.postMessage(editor.innerHTML);
        } catch(e) {}
      }, 300);
    });

    // Insert media HTML into the editor at cursor position
    window.insertMediaToDOM = function(html) {
      editor.focus();
      var selection = window.getSelection();
      if (selection.rangeCount > 0) {
        var range = selection.getRangeAt(0);
        range.deleteContents();
        var fragment = document.createRange().createContextualFragment(html);
        range.insertNode(fragment);
        // Move cursor after inserted content
        range.collapse(false);
        selection.removeAllRanges();
        selection.addRange(range);
      } else {
        editor.innerHTML += html;
      }
      // Notify Flutter
      setTimeout(function() {
        try {
          FlutterBridge.postMessage(editor.innerHTML);
        } catch(e) {}
      }, 100);
    };

    // Get HTML content
    window.getEditorContent = function() {
      return editor.innerHTML;
    };

    // Set HTML content
    window.setEditorContent = function(html) {
      editor.innerHTML = html;
    };

    // Focus editor
    window.focusEditor = function() {
      editor.focus();
      var range = document.createRange();
      range.selectNodeContents(editor);
      range.collapse(false);
      var sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    };

    // Query and report formatting state at cursor
    function reportFormatState() {
      try {
        var b = document.queryCommandState('bold') ? 1 : 0;
        var i = document.queryCommandState('italic') ? 1 : 0;
        var u = document.queryCommandState('underline') ? 1 : 0;
        var s = document.queryCommandState('strikeThrough') ? 1 : 0;
        var ul = document.queryCommandState('insertUnorderedList') ? 1 : 0;
        var ol = document.queryCommandState('insertOrderedList') ? 1 : 0;
        var jl = document.queryCommandState('justifyLeft') ? 1 : 0;
        var jc = document.queryCommandState('justifyCenter') ? 1 : 0;
        var jr = document.queryCommandState('justifyRight') ? 1 : 0;

        // Detect current block format (h1, h2, h3, blockquote)
        var block = document.queryCommandValue('formatBlock').toLowerCase();
        var h1 = (block === 'h1') ? 1 : 0;
        var h2 = (block === 'h2') ? 1 : 0;
        var h3 = (block === 'h3') ? 1 : 0;
        var bq = (block === 'blockquote') ? 1 : 0;

        var msg = 'bold:'+b+',italic:'+i+',underline:'+u+',strikeThrough:'+s
          +',unorderedList:'+ul+',orderedList:'+ol
          +',justifyLeft:'+jl+',justifyCenter:'+jc+',justifyRight:'+jr
          +',h1:'+h1+',h2:'+h2+',h3:'+h3+',blockquote:'+bq;
        FormatState.postMessage(msg);
      } catch(e) {}
    }

    // Listen for selection changes and key events
    document.addEventListener('selectionchange', reportFormatState);
    editor.addEventListener('keyup', reportFormatState);
    editor.addEventListener('mouseup', reportFormatState);
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
