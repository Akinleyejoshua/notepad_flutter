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
  }) : mediaPaths = mediaPaths ?? [], lastEdited = lastEdited ?? DateTime.now();

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
}