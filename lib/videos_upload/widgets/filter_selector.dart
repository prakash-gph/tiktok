import 'package:flutter/material.dart';

typedef OnFilterChanged = void Function(int index);

class FilterDefinition {
  final String id;
  final String label;
  final Color? overlayColor;
  final BlendMode? blendMode;
  final List<double>? colorMatrix;

  FilterDefinition({
    required this.id,
    required this.label,
    this.overlayColor,
    this.blendMode,
    this.colorMatrix,
  });
}

final demoFilters = <FilterDefinition>[
  FilterDefinition(id: 'normal', label: 'Normal'),
  FilterDefinition(
    id: 'boost',
    label: 'Boost',
    colorMatrix: [
      1.2,
      0,
      0,
      0,
      0,
      0,
      1.1,
      0,
      0,
      0,
      0,
      0,
      1.05,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  // FilterDefinition(
  //   id: 'warm',
  //   label: 'Warm',
  //   overlayColor: Colors.orange.withOpacity(0.12),
  //   blendMode: BlendMode.overlay,
  // ),
  // FilterDefinition(
  //   id: 'cool',
  //   label: 'Cool',
  //   overlayColor: Colors.blue.withOpacity(0.08),
  //   blendMode: BlendMode.overlay,
  // ),
];

class FilterSelector extends StatefulWidget {
  final OnFilterChanged onFilterChanged;
  final int initial;
  const FilterSelector({
    super.key,
    required this.onFilterChanged,
    this.initial = 0,
  });
  @override
  State<FilterSelector> createState() => _FilterSelectorState();
}

class _FilterSelectorState extends State<FilterSelector> {
  int selected = 0;
  @override
  void initState() {
    selected = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: demoFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = demoFilters[i];
          final active = i == selected;
          return GestureDetector(
            onTap: () {
              setState(() => selected = i);
              widget.onFilterChanged(i);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: active ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(f.label)),
            ),
          );
        },
      ),
    );
  }
}
