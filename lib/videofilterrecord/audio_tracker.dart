class AudioTrack {
  final String title;
  final String? artist;
  final String url; // local file path or remote URL

  AudioTrack({required this.title, this.artist, required this.url});

  factory AudioTrack.fromJson(Map<String, dynamic> j) => AudioTrack(
    title: j['title'] ?? 'Unknown',
    artist: j['artist'],
    url: j['url'],
  );
}
