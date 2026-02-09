import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/profile_viewmodel.dart';
import '../../wifi/view/wifi_config_view.dart';
import '../../wifi/viewmodel/wifi_viewmodel.dart';
import '../../wifi/services/wifi_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _smsAlertsEnabled = true;
  bool _pushAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   foregroundColor: theme.colorScheme.onSurface,
      //   centerTitle: true,
      //   title: const Text('Profile'),
      // ),
      body: SafeArea(
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, _) {
            final user = viewModel.user;
            final displayName =
                (user?.fullName?.isNotEmpty ?? false) ? user!.fullName! : 'Guest User';
            final email = user?.email ?? 'No email';
            final farmName = user?.farmName;
            final location = user?.location;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    displayName: displayName,
                    email: email,
                    photoUrl: user?.photoUrl,
                    onEditProfile: () => _showEditProfileDialog(context, viewModel),
                  ),
                  const SizedBox(height: 20),
                  _ProfileCard(
                    title: 'Farm Profile',
                    leading: Icons.agriculture_outlined,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: viewModel.isBusy
                          ? null
                          : () => _showEditProfileDialog(context, viewModel),
                    ),
                    children: [
                      _InfoTile(
                        icon: Icons.spa_outlined,
                        label: 'Farm name',
                        value: _presentValue(farmName),
                      ),
                      const SizedBox(height: 12),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: _presentValue(location),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ProfileCard(
                    title: 'Device & Connectivity',
                    leading: Icons.settings_input_antenna,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.wifi_tethering),
                        title: const Text('WiFi configuration'),
                        subtitle: const Text('Connect ESP32 to your network'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => WiFiViewModel(WiFiService()),
                                child: const WiFiConfigView(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ProfileCard(
                    title: 'Security & Preferences',
                    leading: Icons.shield_outlined,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change password'),
                        subtitle: const Text('Update your password for better security'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePasswordDialog(context, viewModel),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.sms_outlined),
                        title: const Text('SMS alerts'),
                        subtitle: const Text('Enable GSM fallback notifications'),
                        value: _smsAlertsEnabled,
                        onChanged: (value) {
                          setState(() => _smsAlertsEnabled = value);
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Push notifications'),
                        subtitle: const Text('Receive ESP32 status updates'),
                        value: _pushAlertsEnabled,
                        onChanged: (value) {
                          setState(() => _pushAlertsEnabled = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (viewModel.hasError)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage ?? 'Something went wrong.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (viewModel.hasError) const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed:
                        viewModel.isBusy ? null : () => _confirmLogout(context, viewModel),
                    icon: viewModel.isBusy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: Text(viewModel.isBusy ? 'Signing out...' : 'Logout'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _presentValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not set';
    }
    return value;
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    ProfileViewModel viewModel,
  ) async {
    final fullNameController = TextEditingController(text: viewModel.user?.fullName ?? '');
    final farmNameController = TextEditingController(text: viewModel.user?.farmName ?? '');
    final locationController = TextEditingController(text: viewModel.user?.location ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: farmNameController,
                  decoration: const InputDecoration(
                    labelText: 'Farm name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: viewModel.isSavingProfile
                  ? null
                  : () async {
                      final success = await viewModel.updateProfile(
                        fullName: fullNameController.text.trim(),
                        farmName: farmNameController.text.trim(),
                        location: locationController.text.trim(),
                      );
                      if (context.mounted && success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully'),
                          ),
                        );
                      }
                    },
              child: viewModel.isSavingProfile
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    ProfileViewModel viewModel,
  ) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: viewModel.isChangingPassword
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 6 characters'),
                          ),
                        );
                        return;
                      }

                      final success =
                          await viewModel.changePassword(newPasswordController.text);
                      if (context.mounted && success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully'),
                          ),
                        );
                      }
                    },
              child: viewModel.isChangingPassword
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, ProfileViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: viewModel.isLoggingOut
                  ? null
                  : () async {
                      await viewModel.logout();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: viewModel.isLoggingOut
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.onEditProfile,
  });

  final String displayName;
  final String email;
  final String? photoUrl;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: theme.colorScheme.primary,
              foregroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? Image.network(photoUrl!).image
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 42, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // OutlinedButton.icon(
          //   onPressed: onEditProfile,
          //   icon: const Icon(Icons.edit_outlined, size: 18),
          //   label: const Text('Edit profile'),
          // ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.title,
    required this.children,
    this.leading,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final IconData? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null)
                  Icon(leading, color: theme.colorScheme.primary),
                if (leading != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
