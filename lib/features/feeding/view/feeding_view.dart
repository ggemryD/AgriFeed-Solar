import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/feeding_schedule_model.dart';
import '../viewmodel/feeding_viewmodel.dart';

class FeedingView extends StatefulWidget {
  const FeedingView({super.key});

  @override
  State<FeedingView> createState() => _FeedingViewState();
}

class _FeedingViewState extends State<FeedingView> {
  @override
  void initState() {
    super.initState();
    // Ensure initial refresh when the view is first shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedingViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedingViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading && viewModel.schedules.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              _buildHeader(context, viewModel),
              const SizedBox(height: 20),
              _ManualFeedCard(viewModel: viewModel),
              const SizedBox(height: 20),
              _LiveLoadCard(viewModel: viewModel),
              const SizedBox(height: 20),
              _ScheduleSection(viewModel: viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, FeedingViewModel viewModel) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feeding Management',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fine-tune dispensing, monitor real-time weight, and maintain schedules.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        if (viewModel.hasError) ...[
          const SizedBox(height: 12),
          MaterialBanner(
            padding: const EdgeInsets.all(12),
            backgroundColor: Colors.red.withValues(alpha: 0.08),
            leading: const Icon(Icons.error_outline, color: Colors.red),
            content: Text(viewModel.error.toString()),
            actions: [
              TextButton(
                onPressed: () => viewModel.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ManualFeedCard extends StatelessWidget {
  const _ManualFeedCard({required this.viewModel});

  final FeedingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manual Dispense',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Chip(
                  label: const Text('Instant'),
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${viewModel.manualQuantity.toStringAsFixed(1)} kg',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Slider(
              value: viewModel.manualQuantity,
              min: 1,
              max: 5,
              divisions: 40,
              label: '${viewModel.manualQuantity.toStringAsFixed(1)} kg',
              onChanged:
                  viewModel.isDispensing
                      ? null
                      : (value) => viewModel.setManualQuantity(value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('1 kg'), Text('5 kg')],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed:
                  viewModel.isDispensing ? null : () => viewModel.dispenseNow(),
              icon:
                  viewModel.isDispensing
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.play_arrow_rounded),
              label: Text(
                viewModel.isDispensing ? 'Dispensing…' : 'Dispense Now',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveLoadCard extends StatelessWidget {
  const _LiveLoadCard({required this.viewModel});

  final FeedingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final load = viewModel.loadCellKg;
    final backupStatus =
        load != null && load > 8
            ? 'Backup storage is sufficient'
            : 'Backup storage running low';
    final backupColor = load != null && load > 8 ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.scale,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Real-time Weight Sensor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              load == null ? '-- kg' : '${load.toStringAsFixed(2)} kg',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.inventory_rounded, size: 18, color: backupColor),
                const SizedBox(width: 6),
                Text(
                  backupStatus,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: backupColor,
                    fontWeight: FontWeight.w600,
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

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.viewModel});

  final FeedingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scheduled Feeding',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => viewModel.refresh(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reload schedules',
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _createSchedule(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...viewModel.schedules.map(
              (schedule) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _ScheduleTile(
                  schedule: schedule,
                  onToggle:
                      (enabled) =>
                          viewModel.toggleSchedule(schedule.id, enabled),
                  onEdit: () => _editSchedule(context, schedule),
                  onDelete: () => _confirmDelete(context, schedule),
                ),
              ),
            ),
            if (viewModel.schedules.isEmpty)
              const Text('No schedules configured yet.'),
          ],
        ),
      ),
    );
  }

  Future<void> _editSchedule(
    BuildContext context,
    FeedingScheduleModel schedule,
  ) async {
    final viewModel = context.read<FeedingViewModel>();
    final weightOptions = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];
    var selectedWeight = weightOptions.firstWhere(
      (w) => (w - schedule.weightKg).abs() < 0.1,
      orElse: () => 2.5,
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adjust ${schedule.timeLabel} feeding'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select feed weight:'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: weightOptions.map((weight) {
                      final isSelected = weight == selectedWeight;
                      return FilterChip(
                        label: Text('${weight.toStringAsFixed(1)} kg'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => selectedWeight = weight);
                          }
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                viewModel.updateSchedule(schedule.copyWith(weightKg: selectedWeight));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSchedule(BuildContext context) async {
    final viewModel = context.read<FeedingViewModel>();
    const hourOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    final minuteOptions = List<int>.generate(12, (index) => index * 5);
    final weightOptions = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];
    var selectedHour = 7;
    var selectedMinute = 0;
    var selectedWeight = 2.5;
    var period = 'AM';
    var isEnabled = true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add feeding schedule'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time Selection'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 96,
                                child: DropdownButtonFormField<int>(
                                  value: selectedHour,
                                  decoration: const InputDecoration(labelText: 'Hour'),
                                  items: hourOptions
                                      .map(
                                        (hour) => DropdownMenuItem<int>(
                                          value: hour,
                                          child: Text(hour.toString().padLeft(2, '0')),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => selectedHour = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: DropdownButtonFormField<int>(
                                  value: selectedMinute,
                                  decoration: const InputDecoration(labelText: 'Minute'),
                                  items: minuteOptions
                                      .map(
                                        (minute) => DropdownMenuItem<int>(
                                          value: minute,
                                          child: Text(minute.toString().padLeft(2, '0')),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => selectedMinute = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: DropdownButtonFormField<String>(
                                  value: period,
                                  decoration: const InputDecoration(labelText: 'Period'),
                                  items: const [
                                    DropdownMenuItem(value: 'AM', child: Text('AM')),
                                    DropdownMenuItem(value: 'PM', child: Text('PM')),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => period = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('Select feed weight:'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: weightOptions.map((weight) {
                              final isSelected = weight == selectedWeight;
                              return FilterChip(
                                label: Text('${weight.toStringAsFixed(1)} kg'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => selectedWeight = weight);
                                  }
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Schedule enabled'),
                            value: isEnabled,
                            onChanged: (value) => setState(() => isEnabled = value),
                          ),
                        ],
                      ),
                    ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    var hour24 = selectedHour % 12;
                    if (period == 'PM') {
                      hour24 += 12;
                    } else if (period == 'AM' && selectedHour == 12) {
                      hour24 = 0;
                    }

                    final success = await viewModel.createSchedule(
                      hour: hour24,
                      minute: selectedMinute,
                      weightKg: selectedWeight,
                      enabled: isEnabled,
                    );

                    if (!context.mounted) {
                      return;
                    }

                    if (success) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Schedule added')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FeedingScheduleModel schedule,
  ) async {
    final viewModel = context.read<FeedingViewModel>();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete schedule'),
          content: Text(
            'Remove the ${schedule.timeLabel} feeding schedule? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final success = await viewModel.deleteSchedule(schedule.id);
    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${schedule.timeLabel} schedule removed'),
        ),
      );
    }
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final FeedingScheduleModel schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = schedule.isEnabled;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color:
            isEnabled
                ? colorScheme.primary.withValues(alpha: 0.08)
                : const Color(0xFF9CA3AF).withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: isEnabled ? colorScheme.primary : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.timeLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.weightKg.toStringAsFixed(1)} kg', //per cycle
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Switch(value: isEnabled, onChanged: onToggle),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit weight',
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Delete schedule',
          ),
        ],
      ),
    );
  }
}
