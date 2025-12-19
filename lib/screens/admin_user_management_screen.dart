import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  static const double _roleBadgePadding = 12.0;
  static const double _roleBadgeRadius = 16.0;
  static const double _roleBadgeBorderWidth = 1.5;
  static const double _roleIconSize = 16.0;

  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      _allUsers = await auth.fetchAllUsers();
      _applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((u) {
          return u.displayName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _updateRole(AppUser user, UserRole role) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.updateUserRole(user.uid, role);
      setState(() {
        final idx = _allUsers.indexWhere((u) => u.uid == user.uid);
        if (idx != -1) {
          _allUsers[idx] = _allUsers[idx].copyWith(role: role);
          _applyFilter();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated ${user.displayName}\'s role to ${role.displayName}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.currentAppUser?.role.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin: Manage Users')),
        body: const Center(child: Text('Only admins can access this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Manage Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search by name or email',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _query = v;
                _applyFilter();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          title: Text(user.displayName),
                          subtitle: Text(user.email),
                          trailing: _RoleBadgeButton(
                            user: user,
                            onRoleChanged: (role) => _updateRole(user, role),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }


}

class _RoleBadgeButton extends StatelessWidget {
  final AppUser user;
  final void Function(UserRole) onRoleChanged;

  const _RoleBadgeButton({required this.user, required this.onRoleChanged});

  static IconData _getRoleIcon(UserRole role) =>
      role.isAdmin ? Icons.admin_panel_settings : Icons.person;

  static Color _getRoleColor(UserRole role) =>
      role.isAdmin ? Colors.red : Colors.blue;

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);
    final roleIcon = _getRoleIcon(user.role);

    return PopupMenuButton<UserRole>(
      tooltip: 'Change role',
      onSelected: onRoleChanged,
      itemBuilder: (context) => UserRole.values
          .map(
            (r) => PopupMenuItem(
              value: r,
              child: Row(
                children: [
                  Icon(_getRoleIcon(r), size: 18, color: _getRoleColor(r)),
                  const SizedBox(width: 8),
                  Text(r.displayName),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _AdminUserManagementScreenState._roleBadgePadding,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: roleColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            _AdminUserManagementScreenState._roleBadgeRadius,
          ),
          border: Border.all(
            color: roleColor,
            width: _AdminUserManagementScreenState._roleBadgeBorderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              roleIcon,
              size: _AdminUserManagementScreenState._roleIconSize,
              color: roleColor,
            ),
            const SizedBox(width: 6),
            Text(
              user.role.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: roleColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: _AdminUserManagementScreenState._roleIconSize,
              color: roleColor,
            ),
          ],
        ),
      ),
    );
  }
}
