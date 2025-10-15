class SavedVideoModel {
  final String videoId;
  final String videoUrl;
  final String thumbnailUrl;
  final String description;

  SavedVideoModel({
    required this.videoId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
  });

  factory SavedVideoModel.fromMap(Map<String, dynamic> data) {
    return SavedVideoModel(
      videoId: data['videoId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'savedAt': DateTime.now(),
    };
  }
}
