// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// import '../../../widgets/status_card.dart';
// import '../../dashboard/viewmodel/dashboard_viewmodel.dart';

// class DashboardView extends StatelessWidget {
//   const DashboardView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<DashboardViewModel>(
//       builder: (context, viewModel, _) {
//         if (viewModel.isLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (viewModel.hasError ||
//             viewModel.feedStatus == null ||
//             viewModel.powerStatus == null) {
//           return _buildErrorState(context, viewModel);
//         }

//         final feedStatus = viewModel.feedStatus!;
//         final powerStatus = viewModel.powerStatus!;

//         return RefreshIndicator(
//           onRefresh: () async => viewModel.refresh(),
//           child: ListView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
//             children: [
//               _buildHeader(context),
//               // const SizedBox(height: 20),
//               // StatusCard(
//               //   title: 'Solar Power Status',
//               //   icon: Icons.wb_sunny_outlined,
//               //   content: Column(
//               //     crossAxisAlignment: CrossAxisAlignment.start,
//               //     children: [
//               //       Row(
//               //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //         children: [
//               //           Text(
//               //             '${powerStatus.batteryPercentage}%',
//               //             style: Theme.of(context).textTheme.headlineMedium
//               //                 ?.copyWith(fontWeight: FontWeight.bold),
//               //           ),
//               //           Chip(
//               //             label: Text(powerStatus.chargingSource),
//               //             backgroundColor: Theme.of(
//               //               context,
//               //             ).colorScheme.primary.withValues(alpha: 0.08),
//               //           ),
//               //         ],
//               //       ),
//               //       const SizedBox(height: 12),
//               //       ClipRRect(
//               //         borderRadius: BorderRadius.circular(12),
//               //         child: LinearProgressIndicator(
//               //           value: powerStatus.batteryPercentage / 100,
//               //           minHeight: 10,
//               //         ),
//               //       ),
//               //     ],
//               //   ),
//               //   footer: Row(
//               //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //     children: [
//               //       _StatusLabel(
//               //         icon: Icons.power_settings_new,
//               //         label:
//               //             powerStatus.isOnline ? 'Machine Online' : 'Offline',
//               //         color:
//               //             powerStatus.isOnline
//               //                 ? Colors.green
//               //                 : Colors.redAccent,
//               //       ),
//               //       _StatusLabel(
//               //         icon: Icons.settings_input_component,
//               //         label:
//               //             powerStatus.motorActive
//               //                 ? 'Motor Active'
//               //                 : 'Motor Idle',
//               //         color:
//               //             powerStatus.motorActive
//               //                 ? Colors.orange
//               //                 : Theme.of(context).colorScheme.primary,
//               //       ),
//               //     ],
//               //   ),
//               // ),
//               const SizedBox(height: 20),
//               StatusCard(
//                 title: 'Feed Storage Status',  // Changed from "Feed Hopper Status"
//                 icon: Icons.inventory_2_outlined,
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           feedStatus.feedLevel != null 
//                               ? '${feedStatus.feedLevel}%'
//                               : '${feedStatus.currentWeightKg.toStringAsFixed(1)} kg',
//                           style: Theme.of(context).textTheme.headlineMedium
//                               ?.copyWith(fontWeight: FontWeight.bold),
//                         ),
//                         // Show sensor indicator
//                         if (feedStatus.feedLevel != null)
//                           Chip(
//                             label: const Text('Live Sensor'),
//                             avatar: const Icon(Icons.sensors, size: 16),
//                             backgroundColor: Colors.green.withOpacity(0.1),
//                             labelStyle: const TextStyle(
//                               color: Colors.green,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       feedStatus.feedLevel != null
//                           ? 'Real-time ultrasonic measurement'
//                           : 'Capacity ${feedStatus.capacityKg.toStringAsFixed(0)} kg',
//                       style: Theme.of(
//                         context,
//                       ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//                     ),
//                     const SizedBox(height: 14),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: LinearProgressIndicator(
//                         value: feedStatus.fillPercentage,
//                         minHeight: 10,
//                         backgroundColor: Colors.grey[200],
//                         color:
//                             feedStatus.isLow
//                                 ? Colors.redAccent
//                                 : Theme.of(context).colorScheme.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//                 footer: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Show storage status from ESP32
//                     if (feedStatus.storageStatus != null)
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 12),
//                         child: Row(
//                           children: [
//                             Icon(
//                               feedStatus.storageStatus == 'LOW' 
//                                   ? Icons.warning_amber_rounded 
//                                   : Icons.check_circle_outline,
//                               size: 18,
//                               color: feedStatus.storageStatus == 'LOW' 
//                                   ? Colors.redAccent 
//                                   : Colors.green,
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               feedStatus.storageStatus == 'LOW' 
//                                   ? 'Low Feed - Please Refill' 
//                                   : 'Feed Level Sufficient',
//                               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                                 color: feedStatus.storageStatus == 'LOW' 
//                                     ? Colors.redAccent 
//                                     : Colors.green,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     _TimelineRow(
//                       icon: Icons.schedule,
//                       label: 'Last feeding',
//                       value: _formatDate(feedStatus.lastFeedingTime),
//                     ),
//                     const SizedBox(height: 12),
//                     _TimelineRow(
//                       icon: Icons.timer,
//                       label: 'Next schedule',
//                       value: _formatDate(feedStatus.nextFeedingTime),
//                     ),
//                   ],
//                 ),
//                 // background:
//                 //     feedStatus.isLow
//                 //         ? Colors.redAccent.withValues(alpha: 0.06)
//                 //         : null,
//                 // border: 
//                 //     feedStatus.isLow 
//                 //         ? Border.all(color: Colors.redAccent, width: 2)
//                 //         : null,
//               ),
//               const SizedBox(height: 20),
              
//               // TODO: TESTING CARD - Remove this after servo testing is complete
//               // This card is for testing the servo control functionality
//               // StatusCard(
//               //   title: 'Servo Control (Test)',
//               //   icon: Icons.settings_remote_outlined,
//               //   content: Column(
//               //     crossAxisAlignment: CrossAxisAlignment.start,
//               //     children: [
//               //       Row(
//               //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //         children: [
//               //           Text(
//               //             'Test Mode',
//               //             style: Theme.of(context).textTheme.headlineMedium
//               //                 ?.copyWith(fontWeight: FontWeight.bold),
//               //           ),
//               //           Chip(
//               //             label: const Text('DEBUG'),
//               //             backgroundColor: Colors.orange.withValues(alpha: 0.12),
//               //             labelStyle: const TextStyle(color: Colors.orange),
//               //           ),
//               //         ],
//               //       ),
//               //       const SizedBox(height: 12),
//               //       Text(
//               //         'Control feeder servo for testing purposes.\nUpdates /mainStorage/feederCommand in Firebase.',
//               //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               //           color: Colors.grey[600],
//               //         ),
//               //       ),
//               //       const SizedBox(height: 16),
//               //       Row(
//               //         children: [
//               //           Expanded(
//               //             child: FilledButton.icon(
//               //               onPressed: () => viewModel.openFeeder(),
//               //               icon: const Icon(Icons.lock_open),
//               //               label: const Text('OPEN'),
//               //               style: FilledButton.styleFrom(
//               //                 backgroundColor: Colors.green,
//               //                 foregroundColor: Colors.white,
//               //               ),
//               //             ),
//               //           ),
//               //           const SizedBox(width: 12),
//               //           Expanded(
//               //             child: FilledButton.icon(
//               //               onPressed: () => viewModel.closeFeeder(),
//               //               icon: const Icon(Icons.lock),
//               //               label: const Text('CLOSE'),
//               //               style: FilledButton.styleFrom(
//               //                 backgroundColor: Colors.red,
//               //                 foregroundColor: Colors.white,
//               //               ),
//               //             ),
//               //           ),
//               //           const SizedBox(width: 12),
//               //           FilledButton.icon(
//               //             onPressed: () => viewModel.resetFeederCommand(),
//               //             icon: const Icon(Icons.refresh),
//               //             label: const Text('RESET'),
//               //             style: FilledButton.styleFrom(
//               //               backgroundColor: Colors.grey,
//               //               foregroundColor: Colors.white,
//               //             ),
//               //           ),
//               //         ],
//               //       ),
//               //     ],
//               //   ),
//               //   footer: Column(
//               //     crossAxisAlignment: CrossAxisAlignment.start,
//               //     children: [
//               //       Text(
//               //         'Current Command: ${viewModel.feederCommand ?? "NONE"}',
//               //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               //           fontWeight: FontWeight.w600,
//               //           color: Colors.blue,
//               //         ),
//               //       ),
//               //       const SizedBox(height: 4),
//               //       Text(
//               //         'Status: ${viewModel.feederStatus ?? "UNKNOWN"}',
//               //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               //           color: Colors.grey[600],
//               //         ),
//               //       ),
//               //     ],
//               //   ),
//               //   background: Colors.orange.withValues(alpha: 0.03),
//               // ),
//               // END OF TESTING CARD
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     final theme = Theme.of(context);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Today at a glance',
//           style: theme.textTheme.headlineSmall?.copyWith(
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Monitor feed levels in real time.', // Monitor power, feed levels, and machine status in real time.
//           style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorState(BuildContext context, DashboardViewModel viewModel) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.cloud_off, size: 64, color: Colors.grey[500]),
//             const SizedBox(height: 16),
//             Text(
//               'Unable to load dashboard data',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Check your connection or try refreshing in a moment.',
//               textAlign: TextAlign.center,
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 20),
//             FilledButton(
//               onPressed: viewModel.refresh,
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime? date) {
//     if (date == null) return 'No data';
//     final formatter = DateFormat('MMM d • hh:mm a');
//     return formatter.format(date);
//   }
// }

// class _StatusLabel extends StatelessWidget {
//   const _StatusLabel({
//     required this.icon,
//     required this.label,
//     required this.color,
//   });

//   final IconData icon;
//   final String label;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: color),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//             color: color,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _TimelineRow extends StatelessWidget {
//   const _TimelineRow({
//     required this.icon,
//     required this.label,
//     required this.value,
//   });

//   final IconData icon;
//   final String label;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: Theme.of(
//               context,
//             ).colorScheme.primary.withValues(alpha: 0.12),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(icon, color: Theme.of(context).colorScheme.primary),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//               ),
//               Text(
//                 value,
//                 style: Theme.of(
//                   context,
//                 ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// ----------------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../widgets/status_card.dart';
import '../../dashboard/viewmodel/dashboard_viewmodel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (viewModel.hasError ||
            viewModel.feedStatus == null ||
            viewModel.powerStatus == null) {
          return _buildErrorState(context, viewModel);
        }

        final feedStatus = viewModel.feedStatus!;
        final powerStatus = viewModel.powerStatus!;

        return RefreshIndicator(
          onRefresh: () async => viewModel.refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              StatusCard(
                title: 'Feed Storage Status',  // Changed from "Feed Hopper Status"
                icon: Icons.inventory_2_outlined,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feedStatus.feedLevel != null 
                              ? '${feedStatus.feedLevel}%'
                              : '${feedStatus.currentWeightKg.toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        // Show sensor indicator
                        if (feedStatus.feedLevel != null)
                          Chip(
                            label: const Text('Live Sensor'),
                            avatar: const Icon(Icons.sensors, size: 16),
                            backgroundColor: Colors.green.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feedStatus.feedLevel != null
                          ? 'Real-time ultrasonic measurement'
                          : 'Capacity ${feedStatus.capacityKg.toStringAsFixed(0)} kg',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: feedStatus.fillPercentage,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        color:
                            feedStatus.isLow
                                ? Colors.redAccent
                                : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show storage status from ESP32
                    if (feedStatus.storageStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              feedStatus.storageStatus == 'LOW' 
                                  ? Icons.warning_amber_rounded 
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: feedStatus.storageStatus == 'LOW' 
                                  ? Colors.redAccent 
                                  : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              feedStatus.storageStatus == 'LOW' 
                                  ? 'Low Feed - Please Refill' 
                                  : 'Feed Level Sufficient',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: feedStatus.storageStatus == 'LOW' 
                                    ? Colors.redAccent 
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _TimelineRow(
                      icon: Icons.schedule,
                      label: 'Last feeding',
                      value: _formatDate(feedStatus.lastFeedingTime),
                    ),
                    const SizedBox(height: 12),
                    _TimelineRow(
                      icon: Icons.timer,
                      label: 'Next schedule',
                      value: _formatDate(feedStatus.nextFeedingTime),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today at a glance',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor feed levels in real time.', // Monitor power, feed levels, and machine status in real time.
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, DashboardViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'Unable to load dashboard data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection or try refreshing in a moment.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: viewModel.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No data';
    final formatter = DateFormat('MMM d • hh:mm a');
    return formatter.format(date);
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
