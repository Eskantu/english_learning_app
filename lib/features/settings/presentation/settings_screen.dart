import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../features/learning/domain/entities/learning_item.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _notificationsEnabled = true;
  int _hour = 20;
  int _minute = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bool enabled =
        await ServiceLocator.notificationService.getNotificationsEnabled();
    final int hour = await ServiceLocator.notificationService.getReminderHour();
    final int minute =
        await ServiceLocator.notificationService.getReminderMinute();

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = enabled;
      _hour = hour;
      _minute = minute;
      _loading = false;
    });
  }

  Future<void> _rescheduleReminder() async {
    final List<LearningItem> dueItems =
        await ServiceLocator.getItemsToReviewUseCase(DateTime.now());
    await ServiceLocator.notificationService.scheduleDailyReviewReminder(
      dueCount: dueItems.length,
    );
  }

  Future<void> _onToggleChanged(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });

    await ServiceLocator.notificationService.setNotificationsEnabled(enabled);
    await _rescheduleReminder();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });

    await ServiceLocator.notificationService.setReminderTime(
      hour: _hour,
      minute: _minute,
    );
    await _rescheduleReminder();
  }

  String _formatTime12h(int hour, int minute) {
    final int normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    final String mm = minute.toString().padLeft(2, '0');
    return '$normalizedHour:$mm $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF4F8FF), Color(0xFFEFF7F3)],
          ),
        ),
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _SettingsCard(
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.notifications_active_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Notifications',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enable daily learning reminders',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _notificationsEnabled,
                            onChanged: _onToggleChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.schedule_rounded),
                              const SizedBox(width: 10),
                              Text(
                                'Reminder time',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _notificationsEnabled ? _pickTime : null,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _notificationsEnabled
                                        ? Colors.white
                                        : const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFDEE4EF),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    _formatTime12h(_hour, _minute),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              _notificationsEnabled
                                                  ? const Color(0xFF2C3E50)
                                                  : const Color(0xFF95A0AD),
                                        ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.edit_rounded),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.calendar_today_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _notificationsEnabled
                                  ? 'Daily reminder scheduled for ${_formatTime12h(_hour, _minute)}'
                                  : 'Notifications disabled',
                              key: const ValueKey<String>(
                                'reminder_preview_text',
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x150C1A33),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
