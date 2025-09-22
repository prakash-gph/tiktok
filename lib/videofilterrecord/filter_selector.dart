import 'package:flutter/material.dart';
import 'package:tiktok/utils/filters.dart';

class FilterSelector extends StatelessWidget {
  final List<VideoFilter> videoFilters;
  final int selectedIndex;
  final ValueChanged<int> onFilterSelected;

  const FilterSelector({
    Key? key,
    required this.videoFilters,
    required this.selectedIndex,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Reduced height to prevent overflow
      margin: const EdgeInsets.only(bottom: 10), // Added margin
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videoFilters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onFilterSelected(index),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 6,
              ), // Reduced margin
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: selectedIndex == index
                    ? Colors.red
                    : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40, // Reduced size
                    height: 40, // Reduced size
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: selectedIndex == index ? 2 : 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced spacing
                  Text(
                    videoFilters[index].name,
                    style: const TextStyle(fontSize: 10), // Reduced font size
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
