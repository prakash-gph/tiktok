import 'package:flutter/material.dart';

typedef DurationCallback = void Function(int seconds);

class DurationSelector extends StatelessWidget {
  final int selected;
  final DurationCallback onChanged;
  const DurationSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('15s'),
          selected: selected == 15,
          onSelected: (_) => onChanged(15),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('30s'),
          selected: selected == 30,
          onSelected: (_) => onChanged(30),
        ),
      ],
    );
  }
}
