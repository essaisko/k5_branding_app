import 'package:flutter/material.dart';

class AttributeSelector extends StatelessWidget {
  final List<String> attributeLabels;
  final int selectedAttributeIndex;
  final Function(int?) onAttributeSelected;

  const AttributeSelector({
    super.key,
    required this.attributeLabels,
    required this.selectedAttributeIndex,
    required this.onAttributeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      alignment: Alignment.center,
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: '편집할 항목 선택',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
        ),
        value: selectedAttributeIndex,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
        items:
            attributeLabels.asMap().entries.map((entry) {
              int idx = entry.key;
              String label = entry.value;
              return DropdownMenuItem<int>(
                value: idx,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
        onChanged: onAttributeSelected,
      ),
    );
  }
}
