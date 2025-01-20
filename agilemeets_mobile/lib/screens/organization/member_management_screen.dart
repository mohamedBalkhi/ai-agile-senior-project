import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/logic/cubits/auth/auth_state.dart';
import 'package:agilemeets/logic/cubits/organization/organization_cubit.dart';
import 'package:agilemeets/logic/cubits/organization/organization_state.dart';
import 'package:agilemeets/widgets/organization/add_members_dialog.dart';
import 'package:agilemeets/widgets/organization/member_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MemberManagementScreen extends StatelessWidget {
  const MemberManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationCubit, OrganizationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Organization Members'),
            bottom: state.status == OrganizationStatus.loading
                ? PreferredSize(
                    preferredSize: Size.fromHeight(2.h),
                    child: const LinearProgressIndicator(),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterOptions(context),
                tooltip: 'Filter Members',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<OrganizationCubit>().loadMembers(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<OrganizationCubit>().loadMembers(),
            child: state.status == OrganizationStatus.loading && state.members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 64.w,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No members found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: state.members.length,
                        itemBuilder: (context, index) {
                          final member = state.members[index];
                          return MemberCard(
                            member: member,
                            onRoleChanged: (isAdmin) {
                              context.read<OrganizationCubit>().setMemberAsAdmin(
                                    member.memberId,
                                    isAdmin,
                                  );
                            },
                          ).animate().fadeIn(
                                delay: Duration(milliseconds: 50 * index),
                                duration: const Duration(milliseconds: 200),
                              );
                        },
                      ),
          ),
          floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (!authState.isAdmin) return const SizedBox();
              return FloatingActionButton.extended(
                onPressed: () => _showAddMemberDialog(context),
                label: const Text('Add Member'),
                icon: const Icon(Icons.person_add),
              ).animate().fadeIn(
                    duration: const Duration(milliseconds: 300),
                    delay: const Duration(milliseconds: 100),
                  );
            },
          ),
        );
      },
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddMembersDialog(),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('All Members'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admins Only'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Regular Members'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.pending),
            title: const Text('Pending Members'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
} 