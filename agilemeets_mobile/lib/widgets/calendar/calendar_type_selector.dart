import 'package:flutter/material.dart';

enum CalendarType {
  personal,
  project,
}

class CalendarTypeSelector extends StatefulWidget {
  final String? projectId;
  final void Function(CalendarType)? onTypeSelected;

  const CalendarTypeSelector({
    super.key,
    this.projectId,
    this.onTypeSelected,
  });

  @override
  State<CalendarTypeSelector> createState() => _CalendarTypeSelectorState();
}

class _CalendarTypeSelectorState extends State<CalendarTypeSelector> {
  CalendarType _selectedType = CalendarType.personal;

  void _handleTypeChange(CalendarType? value) {
    if (value != null) {
      setState(() => _selectedType = value);
      widget.onTypeSelected?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Calendar Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        RadioListTile<CalendarType>(
          title: const Text('All My Meetings'),
          subtitle: const Text('Sync all meetings you\'re part of'),
          value: CalendarType.personal,
          groupValue: _selectedType,
          onChanged: _handleTypeChange,
        ),
        if (widget.projectId != null)
          RadioListTile<CalendarType>(
            title: const Text('Project Meetings'),
            subtitle: const Text('Only meetings for this project'),
            value: CalendarType.project,
            groupValue: _selectedType,
            onChanged: _handleTypeChange,
          ),
      ],
    );
  }
} 