class AudioSelection {
  final String path;
  final double start; // seconds
  final double duration;
  final String? songName; // seconds

  AudioSelection({
    required this.path,
    required this.start,
    required this.duration,
    required this.songName,
  });
}
