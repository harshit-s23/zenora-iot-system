import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/data_source_badge.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _highStressAlerts = true;
  bool _fallDetection = true;
  int _adminTapCount = 0;
  DateTime? _firstTap;

  void _checkAdminAccess() {
    final now = DateTime.now();
    if (_firstTap == null ||
        now.difference(_firstTap!) > const Duration(seconds: 3)) {
      _firstTap = now;
      _adminTapCount = 1;
    } else {
      _adminTapCount++;
      if (_adminTapCount >= 7) {
        _adminTapCount = 0;
        _firstTap = null;
        _openAdmin();
      }
    }
  }

  void _openAdmin() {
    showDialog(
      context: context,
      builder: (_) => _AdminPinDialog(
        onCorrect: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),

                // ── Profile Header ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _checkAdminAccess,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), AppTheme.accentCyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentCyan.withOpacity(0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _initials(provider.userName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.userName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.userRole,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      Text(
                        'Member since ${provider.memberSince}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Edit Profile ──────────────────────────────────────────
                GestureDetector(
                  onTap: () => _showEditProfile(context, provider),
                  child: Container(
                    decoration: AppTheme.glowDecoration(AppTheme.accentCyan),
                    padding: const EdgeInsets.all(14),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined,
                            color: AppTheme.accentCyan, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Profile',
                            style: TextStyle(
                                color: AppTheme.accentCyan,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Device Card ───────────────────────────────────────────
                _sectionLabel('Device'),
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _deviceRow(
                        Icons.bluetooth,
                        'Zenora Device',
                        'ESP32 Connected',
                        AppTheme.accentCyan,
                        trailing: _connectedBadge(),
                      ),
                      const Divider(color: AppTheme.borderColor, height: 20),
                      _deviceRow(
                        Icons.battery_4_bar,
                        'Battery Status',
                        '${(provider.batteryLevel * 100).toInt()}%',
                        AppTheme.accentGreen,
                        trailing: _batteryBar(provider.batteryLevel),
                      ),
                      const Divider(color: AppTheme.borderColor, height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _infoTile('Last Sync', provider.lastSync,
                                AppTheme.textSecondary),
                          ),
                          Expanded(
                            child: _infoTile('Firmware',
                                provider.firmwareVersion, AppTheme.accentCyan),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.borderColor, height: 20),
                      const CloudSyncStatus(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Emergency Contacts ────────────────────────────────────
                _sectionLabel('Emergency Contacts'),
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _contactRow(
                        'Emergency Contact 1',
                        provider.emergencyContact1.isEmpty
                            ? 'Not set'
                            : provider.emergencyContact1,
                        () => _showContactDialog(context, provider, 1),
                      ),
                      const Divider(color: AppTheme.borderColor, height: 20),
                      _contactRow(
                        'Emergency Contact 2',
                        provider.emergencyContact2.isEmpty
                            ? 'Not set'
                            : provider.emergencyContact2,
                        () => _showContactDialog(context, provider, 2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.accentOrange.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppTheme.accentOrange, size: 14),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'SMS will be sent to these contacts if a fall is detected.',
                                style: TextStyle(
                                    color: AppTheme.accentOrange, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Settings ──────────────────────────────────────────────
                _sectionLabel('Settings'),
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    children: [
                      _settingsTile(
                        Icons.notifications_outlined,
                        AppTheme.accentPurple,
                        'Notifications',
                        'Stress alerts & reminders',
                        _notifications,
                        (v) => setState(() => _notifications = v),
                      ),
                      _divider(),
                      _settingsTile(
                        Icons.warning_amber_outlined,
                        AppTheme.accentRed,
                        'High Stress Alerts',
                        'Alert when stress > 75',
                        _highStressAlerts,
                        (v) => setState(() => _highStressAlerts = v),
                      ),
                      _divider(),
                      _settingsTile(
                        Icons.warning_amber_outlined,
                        AppTheme.accentOrange,
                        'Fall Detection',
                        'Send SMS on fall event',
                        _fallDetection,
                        (v) => setState(() => _fallDetection = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── App Info ──────────────────────────────────────────────
                _sectionLabel('App'),
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    children: [
                      _infoListTile(Icons.info_outline, 'Version', 'v1.0.0'),
                      _divider(),
                      _infoListTile(Icons.security_outlined, 'Data Privacy',
                          'View Policy'),
                      _divider(),
                      GestureDetector(
                        onTap: () {},
                        child: _infoListTile(Icons.logout, 'Sign Out', '',
                            color: AppTheme.accentRed),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Zenora Health Intelligence v1.0.0\nBuilt for ESP32 Integration',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfile(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController(text: provider.userName);
    final roleCtrl = TextEditingController(text: provider.userRole);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _inputField('Full Name', nameCtrl),
            const SizedBox(height: 12),
            _inputField('Role / Profession', roleCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  provider.updateProfile(
                      name: nameCtrl.text, role: roleCtrl.text);
                  Navigator.pop(context);
                },
                child: const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(
      BuildContext context, AppProvider provider, int which) {
    final ctrl = TextEditingController(
        text: which == 1
            ? provider.emergencyContact1
            : provider.emergencyContact2);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Emergency Contact $which',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: _inputField('Phone Number (+91...)', ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: AppTheme.background),
            onPressed: () {
              provider.updateProfile(
                ec1: which == 1 ? ctrl.text : null,
                ec2: which == 2 ? ctrl.text : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8),
      );

  Widget _divider() => const Divider(
      color: AppTheme.borderColor, height: 1, indent: 16, endIndent: 16);

  Widget _settingsTile(IconData icon, Color iconColor, String title, String sub,
      bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14)),
                Text(sub,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeColor: AppTheme.accentCyan,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppTheme.accentCyan.withOpacity(0.3)
                  : AppTheme.borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceRow(IconData icon, String title, String sub, Color color,
      {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Text(sub,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _contactRow(String label, String value, VoidCallback onTap) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.phone, color: AppTheme.accentRed, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13)),
              Text(value,
                  style: TextStyle(
                      color: value == 'Not set'
                          ? AppTheme.textMuted
                          : AppTheme.accentCyan,
                      fontSize: 12)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Icon(Icons.edit_outlined,
              color: AppTheme.textSecondary, size: 18),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _infoListTile(IconData icon, String title, String value,
      {Color color = AppTheme.textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title, style: TextStyle(color: color, fontSize: 14))),
          Text(value,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.textMuted, size: 12),
          ],
        ],
      ),
    );
  }

  Widget _connectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
      ),
      child: const Text('Connected',
          style: TextStyle(color: AppTheme.accentGreen, fontSize: 11)),
    );
  }

  Widget _batteryBar(double level) {
    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${(level * 100).toInt()}%',
              style: const TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: level,
              backgroundColor: AppTheme.borderColor,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType:
          hint.contains('Phone') ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.cardBg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentCyan, width: 1.5),
        ),
      ),
    );
  }
}

// ── Admin PIN dialog ─────────────────────────────────────────────────────────
class _AdminPinDialog extends StatefulWidget {
  final VoidCallback onCorrect;

  const _AdminPinDialog({required this.onCorrect});

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final _ctrl = TextEditingController();
  bool _wrong = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('Admin Access',
          style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter PIN to continue',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'PIN',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              errorText: _wrong ? 'Incorrect PIN' : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.accentCyan),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: AppTheme.background),
          onPressed: () {
            if (_ctrl.text == '2580') {
              widget.onCorrect();
            } else {
              setState(() => _wrong = true);
            }
          },
          child: const Text('Enter'),
        ),
      ],
    );
  }
}
