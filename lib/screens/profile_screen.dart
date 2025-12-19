import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'admin_user_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _avatarRadius = 60;
  static const double _avatarInitialSize = 48;
  static const double _sectionSpacing = 32;
  static const double _buttonVerticalPadding = 16;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Refresh user data when profile screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.refreshUserData();
    });
  }

  Future<void> _updateProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser!.uid;

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(
        'users/$userId/profile.jpg',
      );
      await ref.putFile(File(pickedFile.path));
      final photoUrl = await ref.getDownloadURL();

      // Update user profile
      await authService.updateUserPhoto(photoUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authService.currentUser;
    final appUser = authService.currentAppUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: user == null
          ? const Center(child: Text('Please sign in'))
          : RefreshIndicator(
              onRefresh: () => authService.refreshUserData(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: _avatarRadius,
                              backgroundImage: user.photoURL != null
                                  ? CachedNetworkImageProvider(user.photoURL!)
                                  : null,
                              child: user.photoURL == null
                                  ? Text(
                                      user.displayName?[0].toUpperCase() ?? 'U',
                                      style: const TextStyle(
                                        fontSize: _avatarInitialSize,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: _isUploadingPhoto
                                    ? null
                                    : _updateProfilePhoto,
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName ?? 'Anonymous',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        if (appUser?.role.isAdmin ?? false)
                          Chip(
                            label: Text(appUser!.role.displayName),
                            avatar: const Icon(Icons.shield_outlined, size: 18),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${appUser?.reportsSubmitted ?? 0} Reports Submitted',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _sectionSpacing),

                  // Admin Tools (visible only for admins)
                  if (appUser?.role.isAdmin ?? false) ...[
                    Text(
                      'Admin Tools',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings_outlined,
                        ),
                        title: const Text('Manage Users'),
                        subtitle: const Text('View users and change roles'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminUserManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: _sectionSpacing),
                  ],

                  // Settings Section
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Theme Toggle
                  Card(
                    child: SwitchListTile(
                      secondary: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Toggle dark theme'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Notifications
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: const Text('Manage notification preferences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to notifications settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Privacy
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy'),
                      subtitle: const Text('Privacy settings and data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to privacy settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // About
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('App information and version'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'SafeZone',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(
                            Icons.home_work_rounded,
                            size: 48,
                          ),
                          children: [
                            const Text(
                              'Community Watch - Report and track community issues in your neighborhood.',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: _sectionSpacing),

                  // Sign Out Button
                  FilledButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        vertical: _buttonVerticalPadding,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
