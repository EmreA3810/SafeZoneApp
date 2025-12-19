import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
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
          SnackBar(content: Text('Updated ${user.displayName}\'s role to ${role.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.currentAppUser?.role == UserRole.admin;

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
                            child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
                          ),
                          title: Text(user.displayName),
                          subtitle: Text(user.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(user.role.name),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<UserRole>(
                                tooltip: 'Change role',
                                onSelected: (role) => _updateRole(user, role),
                                itemBuilder: (context) => UserRole.values
                                    .map((r) => PopupMenuItem(
                                          value: r,
                                          child: Text(r.name),
                                        ))
                                    .toList(),
                                child: const Icon(Icons.more_vert),
                              ),
                            ],
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
