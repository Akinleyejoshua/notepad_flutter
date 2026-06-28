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

  // Get a formatted preview of the note content for card display
  String getFormattedPreview() {
    // Remove base64 data URIs (images/videos/audio embedded as data:)
    var text = content
        .replaceAll(RegExp(r'data:[^;]+;base64,[A-Za-z0-9+/=\s]+'), '')
        .trim();

    // Convert HTML tags to formatted text representations
    // Headings
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
