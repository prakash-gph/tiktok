// lib/widgets/video_grid_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoGridItem extends StatelessWidget {
  final String videoId;
  final String thumbnailUrl;
  //final int views;

  const VideoGridItem({
    Key? key,
    required this.videoId,
    required this.thumbnailUrl,
    //required this.views,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: thumbnailUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(color: Colors.grey[800]),
          errorWidget: (context, url, error) =>
              Icon(Icons.error, color: Colors.grey),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Row(
            children: [
              Icon(Icons.play_arrow, color: Colors.white, size: 16),
              SizedBox(width: 4),
              // Text(
              //   _formatViews(views),
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 12,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatViews(int views) {
    if (views < 1000) return views.toString();
    if (views < 1000000) return '${(views / 1000).toStringAsFixed(1)}K';
    return '${(views / 1000000).toStringAsFixed(1)}M';
  }
}
