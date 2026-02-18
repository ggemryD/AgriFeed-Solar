import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/alert_item.dart';
import '../viewmodel/alerts_viewmodel.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertsViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertsViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading && viewModel.alerts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final alerts = viewModel.alerts;

        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            itemCount: alerts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHeader(context, viewModel);
              }
              final alert = alerts[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _AlertTile(alert: alert),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AlertsViewModel viewModel) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feeding History & Logs',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View all manual and scheduled feeding activities with timestamps and quantities.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (viewModel.hasError) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.red.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unable to fetch feeding logs',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            viewModel.error.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red[700],
                            ),
                          ),
                          TextButton(
                            onPressed: viewModel.refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !alert.isRead;
    final isFeedingLog = alert.type == AlertType.manualFeed || alert.type == AlertType.scheduledFeed;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color:
            isUnread
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AlertIcon(type: alert.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d • hh:mm a').format(alert.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Show feeding weight and type for feeding logs
          if (isFeedingLog && (alert.feedWeight != null || alert.feedType != null)) ...[
            Row(
              children: [
                Icon(
                  Icons.scale_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                if (alert.feedWeight != null)
                  Text(
                    '${((alert.feedWeight! * 10).floor() / 10.0).toStringAsFixed(1)} kg',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (alert.feedWeight != null && alert.feedType != null)
                  const SizedBox(width: 8),
                if (alert.feedType != null)
                  Chip(
                    label: Text(alert.feedType!),
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(alert.message, style: theme.textTheme.bodyMedium),
          if (alert.statusDetail != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.sms_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.statusDetail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon({required this.type});

  final AlertType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color color;

    switch (type) {
      case AlertType.feedLow:
        icon = Icons.inventory_2;
        color = Colors.orange;
        break;
      case AlertType.feedCompleted:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case AlertType.powerSwitch:
        icon = Icons.electric_bolt;
        color = Colors.blueAccent;
        break;
      case AlertType.systemError:
        icon = Icons.error_outline;
        color = Colors.redAccent;
        break;
      case AlertType.smsStatus:
        icon = Icons.sms_outlined;
        color = colorScheme.primary;
        break;
      case AlertType.manualFeed:
        icon = Icons.touch_app_outlined;
        color = Colors.purple;
        break;
      case AlertType.scheduledFeed:
        icon = Icons.schedule_outlined;
        color = Colors.teal;
        break;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}
