class RwandaFact {
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  RwandaFact({
    required this.title,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  factory RwandaFact.fromJson(Map<String, dynamic> json) {
    return RwandaFact(
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
