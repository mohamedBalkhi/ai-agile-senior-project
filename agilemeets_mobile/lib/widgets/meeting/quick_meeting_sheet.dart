import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:agilemeets/data/enums/meeting_language.dart';
import 'package:agilemeets/data/enums/meeting_type.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_cubit.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_state.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:agilemeets/widgets/custom_text_field.dart';
import 'package:agilemeets/widgets/meeting/member_selector_dialog.dart';

class QuickMeetingSheet extends StatefulWidget {
  final String projectId;

  const QuickMeetingSheet({
    super.key,
    required this.projectId,
  });

  @override
  State<QuickMeetingSheet> createState() => _QuickMeetingSheetState();
}

class _QuickMeetingSheetState extends State<QuickMeetingSheet> {
  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  MeetingType _selectedType = MeetingType.online;
  List<String> _selectedMembers = [];
  bool _isCreating = false;
  MeetingLanguage _selectedLanguage = MeetingLanguage.arabic;

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _showMemberSelector() async {
    final selectedMembers = await showDialog<List<String>>(
      context: context,
      builder: (context) => MemberSelectorDialog(
        selectedMemberIds: _selectedMembers,
        projectId: widget.projectId,
      ),
    );

    if (selectedMembers != null) {
      setState(() => _selectedMembers = selectedMembers);
    }
  }

  Future<void> _createMeeting() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final now = DateTime.now();
      final timezone = await FlutterTimezone.getLocalTimezone();

      await context.read<MeetingCubit>().createMeeting(
        title: _titleController.text,
        goal: _goalController.text,
        language: _selectedLanguage.value,
        type: _selectedType.value,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        timeZone: timezone,
        projectId: widget.projectId,
        memberIds: _selectedMembers,
        reminderTime: now,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating meeting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetingCubit, MeetingState>(
      listener: (context, state) {
        if (state.status == MeetingStateStatus.created) {
          Navigator.pop(context, true);
        } else if (state.status == MeetingStateStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Failed to create meeting')),
          );
          setState(() => _isCreating = false);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Meeting',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: _titleController,
              label: 'Title*',
              hint: 'Enter meeting title',
              prefixIcon: Icons.title_outlined,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: _goalController,
              label: 'Goal (Optional)',
              hint: 'Enter meeting goal',
              prefixIcon: Icons.flag_outlined,
            ),
            SizedBox(height: 16.h),
            _buildLanguageSelector(),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    type: MeetingType.online,
                    icon: Icons.videocam_outlined,
                    label: 'Online',
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildTypeOption(
                    type: MeetingType.inPerson,
                    icon: Icons.people_outline,
                    label: 'In Person',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: _showMemberSelector,
              icon: const Icon(Icons.person_add_outlined),
              label: Text(
                _selectedMembers.isEmpty
                    ? 'Add Members*'
                    : '${_selectedMembers.length} Members Selected',
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                side: BorderSide(
                  color: _selectedMembers.isEmpty
                      ? AppTheme.errorRed
                      : AppTheme.cardBorderGrey,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            FilledButton(
              onPressed: _isCreating ? null : _createMeeting,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Start Meeting'),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language*',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textGrey,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardGrey,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonFormField<MeetingLanguage>(
            value: _selectedLanguage,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.language_outlined, size: 20.w),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            items: MeetingLanguage.values.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(lang.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLanguage = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required MeetingType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.cardBorderGrey,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.textGrey,
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textGrey,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 