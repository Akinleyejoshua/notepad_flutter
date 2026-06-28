class Note {
  String id;
  String title;
  String content; // Rich text content (HTML or Delta JSON)
  List<String> mediaPaths; // Paths to imported media (images, videos, audio)
  DateTime lastEdited;

  Note({
    required this.id,
    required this.title,
    required this.content,
    List<String>? mediaPaths,
    DateTime? lastEdited,
  }) : mediaPaths = mediaPaths ?? [],
       lastEdited = lastEdited ?? DateTime.now();

  Note copyWith({
    String? title,
    String? content,
    List<String>? mediaPaths,
    DateTime? lastEdited,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  // Convert Note to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mediaPaths': mediaPaths,
      'lastEdited': lastEdited.toIso8601String(),
    };
  }

  // Create Note from a Map
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      mediaPaths: List<String>.from(json['mediaPaths'] ?? []),
      lastEdited: DateTime.parse(json['lastEdited'] ?? json['lastModified']),
    );
  }

  // 🌟 NEW: Serialize a Note object into a primitive stringifiable JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mediaPaths': mediaPaths,
      'lastEdited': lastEdited.toIso8601String(),
    };
  }

  bool get hasImages => content.contains('<img');
  bool get hasVideos => content.contains('<video');
  bool get hasAudio => content.contains('<audio');
  bool get hasMedia =>
      mediaPaths.isNotEmpty || hasImages || hasVideos || hasAudio;

  // Get a formatted preview of the note content for card display
  String getFormattedPreview() {
    if (content.isEmpty) return 'No content yet…';

    // Remove base64 data URIs (images/videos/audio embedded as data:) safely without RegExp to avoid StackOverflow on large files
    var text = content;
    int dataIdx = text.indexOf('data:');
    while (dataIdx != -1) {
      int endIdx = -1;
      for (int i = dataIdx; i < text.length; i++) {
        final char = text[i];
        if (char == '"' || char == "'" || char == ' ' || char == '>') {
          endIdx = i;
          break;
        }
      }
      if (endIdx != -1) {
        text = text.replaceRange(dataIdx, endIdx, '');
      } else {
        text = text.substring(0, dataIdx);
        break;
      }
      dataIdx = text.indexOf('data:');
    }
    text = text.trim();

    // Decode Unicode HTML escapes (e.g. \u003c -> <, \u003e -> >)
    text = text.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
    );

    text = text.replaceAllMapped(
      RegExp(r'<h1[^>]*>(.*?)</h1>', caseSensitive: false),
      (m) => 'H1: ${m[1]}',
    );
    text = text.replaceAllMapped(
      RegExp(r'<h2[^>]*>(.*?)</h2>', caseSensitive: false),
      (m) => 'H2: ${m[1]}',
    );
    text = text.replaceAllMapped(
      RegExp(r'<h3[^>]*>(.*?)</h3>', caseSensitive: false),
      (m) => 'H3: ${m[1]}',
    );

    // Paragraphs - extract text content
    text = text.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false),
      (m) => m[1]!.trim(),
    );

    // Bold/Strong
    text = text.replaceAllMapped(
      RegExp(r'<(b|strong)[^>]*>(.*?)</(b|strong)>', caseSensitive: false),
      (m) => '**${m[2]}**',
    );

    // Blockquote
    text = text.replaceAllMapped(
      RegExp(r'<blockquote[^>]*>(.*?)</blockquote>', caseSensitive: false),
      (m) => '💬 ${m[1]}',
    );

    // List items
    text = text.replaceAllMapped(
      RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false),
      (m) => '• ${m[1]}',
    );

    // Replace <br> with space
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ');

    // Remove remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // Decode HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ');

    // Clean up whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Build final preview with media hints
    final hasImages = content.contains('<img');
    final hasVideos = content.contains('<video');
    final hasAudio = content.contains('<audio');
    final List<String> mediaHints = [];
    if (hasImages) mediaHints.add('📷 image');
    if (hasVideos) mediaHints.add('🎥 video');
    if (hasAudio) mediaHints.add('🎤 audio');

    final buffer = StringBuffer();
    if (text.isNotEmpty) {
      buffer.write(text.length > 80 ? '${text.substring(0, 80)}…' : text);
    }
    if (mediaHints.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' · ');
      buffer.write(mediaHints.join(' '));
    }
    return buffer.isEmpty ? 'No content yet…' : buffer.toString();
  }
}
