import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../logic/cubits/project/project_state.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared/loading_indicator.dart';

class MemberSelectorDialog extends StatefulWidget {
  final List<String> selectedMemberIds;
  final String projectId;

  const MemberSelectorDialog({
    super.key,
    required this.selectedMemberIds,
    required this.projectId,
  });

  @override
  State<MemberSelectorDialog> createState() => _MemberSelectorDialogState();
}

class _MemberSelectorDialogState extends State<MemberSelectorDialog> {
  late List<String> _selectedMemberIds;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = List.from(widget.selectedMemberIds);
    context.read<ProjectCubit>().loadProjectMembers(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 0.9.sw,
        height: 0.7.sh,
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Select Members',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: BlocBuilder<ProjectCubit, ProjectState>(
                builder: (context, state) {
                  final currentUserId = context.read<AuthCubit>().state.userIdentifier;
                  final members = state.projectMembers?.where(
                    (member) => member.userId != currentUserId
                  ).toList();
                  
                  if (members == null) {
                    return const Center(child: LoadingIndicator());
                  }

                  final filteredMembers = members.where((member) {
                    return member.name.toLowerCase().contains(_searchQuery) ||
                           member.email.toLowerCase().contains(_searchQuery);
                  }).toList();

                  return ListView.separated(
                    itemCount: filteredMembers.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      final isSelected = _selectedMemberIds.contains(member.memberId);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha:0.1),
                          child: Text(
                            member.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(member.name),
                        subtitle: Text(
                          member.email,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMemberIds.add(member.memberId);
                              } else {
                                _selectedMemberIds.remove(member.memberId);
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedMemberIds);
                    },
                    child: Text(
                      'Select (${_selectedMemberIds.length})',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 