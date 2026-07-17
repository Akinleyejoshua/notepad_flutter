import 'package:path_provider/path_provider.dart';

/// Utility class for managing asset references in note content.
///
/// Assets (images, videos, audio) are stored in the app's documents directory.
/// The database (SharedPreferences) stores the note content with short
/// `media://filename.ext` placeholders instead of full `file:///...` paths.
/// This keeps content lean and makes text search significantly faster
/// by avoiding scanning through long file URIs.
class ContentUtils {
  static const String _mediaScheme = 'media://';

  /// Encodes note content by replacing all `file:///...` URIs that point
  /// to the app's media directory with short `media://filename.ext` tokens.
  ///
  /// Call this BEFORE saving content to persistent storage.
  static Future<String> encodeContent(String content) async {
    if (!content.contains('file://')) return content;

    final mediaDir = await _getMediaDirectory();
    final mediaDirUri = 'file://$mediaDir/';

    String encoded = content;
    int startIdx = 0;

    while (true) {
      final idx = encoded.indexOf(mediaDirUri, startIdx);
      if (idx == -1) break;

      // Find the end of the URI (at a quote, space, or closing tag)
      int endIdx = idx + mediaDirUri.length;
      while (endIdx < encoded.length &&
          encoded[endIdx] != '"' &&
          encoded[endIdx] != "'" &&
          encoded[endIdx] != ' ' &&
          encoded[endIdx] != '>' &&
          encoded[endIdx] != '&') {
        endIdx++;
      }

      final filename = encoded.substring(idx + mediaDirUri.length, endIdx);
      final replacement = '$_mediaScheme$filename';
      encoded = encoded.replaceRange(idx, endIdx, replacement);
      startIdx = idx + replacement.length;
    }

    return encoded;
  }

  /// Decodes note content by replacing all `media://filename.ext` tokens
  /// back to full `file:///path/to/media/filename.ext` URIs.
  ///
  /// Call this BEFORE loading content into the WebView editor for display.
  static Future<String> decodeContent(String content) async {
    if (!content.contains(_mediaScheme)) return content;

    final mediaDir = await _getMediaDirectory();
    final mediaDirUri = 'file://$mediaDir/';

    String decoded = content;
    int startIdx = 0;

    while (true) {
      final idx = decoded.indexOf(_mediaScheme, startIdx);
      if (idx == -1) break;

      // Find end of filename (at a quote, space, or closing tag)
      int endIdx = idx + _mediaScheme.length;
      while (endIdx < decoded.length &&
          decoded[endIdx] != '"' &&
          decoded[endIdx] != "'" &&
          decoded[endIdx] != ' ' &&
          decoded[endIdx] != '>' &&
          decoded[endIdx] != '&') {
        endIdx++;
      }

      final filename = decoded.substring(idx + _mediaScheme.length, endIdx);
      final replacement = '$mediaDirUri$filename';
      decoded = decoded.replaceRange(idx, endIdx, replacement);
      startIdx = idx + replacement.length;
    }

    return decoded;
  }

  /// Strips all `media://...` references from content for clean text search.
  /// Also strips any `file://...` URIs that might still be present.
  /// Returns clean text suitable for keyword matching.
  static String stripAssetRefs(String content) {
    if (content.isEmpty) return content;

    String text = content;

    // Remove media://filename.ext references
    text = text.replaceAllMapped(
      RegExp(r'''media://\S+?(["' \>&]|$)'''),
      (_) => '',
    );

    // Remove file:// URIs
    text = text.replaceAllMapped(
      RegExp(r'''file://\S+?(["' \>&]|$)'''),
      (_) => '',
    );

    // Remove leftover data: URIs (base64 blobs)
    text = text.replaceAllMapped(
      RegExp(r'''data:[^"' >]+?(["' \>&]|$)'''),
      (_) => '',
    );

    return text.trim();
  }

  /// Gets the media directory path.
  static Future<String> _getMediaDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/media';
  }
}
