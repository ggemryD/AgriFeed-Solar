// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';

// import 'core/services/firebase_service.dart';
// import 'core/services/notification_service.dart';
// import 'core/theme/app_theme.dart';
// import 'features/alerts/repository/alerts_repository.dart';
// import 'features/alerts/services/alerts_service.dart';
// import 'features/alerts/view/alerts_view.dart';
// import 'features/alerts/viewmodel/alerts_viewmodel.dart';
// import 'features/auth/repository/auth_repository.dart';
// import 'features/auth/services/auth_service.dart';
// import 'features/auth/view/sign_in_view.dart';
// import 'features/auth/view/splash_view.dart';
// import 'features/auth/viewmodel/auth_viewmodel.dart';
// import 'features/dashboard/repository/dashboard_repository.dart';
// import 'features/dashboard/services/dashboard_service.dart';
// import 'features/dashboard/view/dashboard_view.dart';
// import 'features/dashboard/viewmodel/dashboard_viewmodel.dart';
// import 'features/feeding/repository/feeding_repository.dart';
// import 'features/feeding/services/feeding_service.dart';
// import 'features/feeding/view/feeding_view.dart';
// import 'features/feeding/viewmodel/feeding_viewmodel.dart';
// import 'features/profile/view/profile_view.dart';
// import 'features/profile/viewmodel/profile_viewmodel.dart';
// import 'features/wifi/services/wifi_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
  
//   // Initialize notifications
//   final notificationService = NotificationService();
//   await notificationService.initialize();
  
//   runApp(AgriFeedSolarApp(notificationService: notificationService));
// }

// class AgriFeedSolarApp extends StatelessWidget {
//   const AgriFeedSolarApp({super.key, required this.notificationService});
  
//   final NotificationService notificationService;

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         Provider(create: (_) => FirebaseService()),
//         Provider<AuthService>(
//           create: (context) => AuthService(context.read<FirebaseService>()),
//         ),
//         Provider<AuthRepository>(
//           create: (context) => AuthRepository(context.read<AuthService>()),
//         ),
//         ChangeNotifierProvider(
//           create: (context) => AuthViewModel(context.read<AuthRepository>()),
//         ),
//         Provider<DashboardService>(
//           create: (context) => DashboardService(context.read<FirebaseService>()),
//         ),
//         Provider<DashboardRepository>(
//           create: (context) => DashboardRepository(context.read<DashboardService>()),
//         ),
//         ChangeNotifierProvider(
//           create: (context) =>
//               DashboardViewModel(context.read<DashboardRepository>()),
//         ),
//         Provider<FeedingService>(
//           create: (context) => FeedingService(context.read<FirebaseService>()),
//         ),
//         Provider<FeedingRepository>(
//           create: (context) => FeedingRepository(context.read<FeedingService>()),
//         ),
//         ChangeNotifierProvider(
//           create: (context) =>
//               FeedingViewModel(context.read<FeedingRepository>()),
//         ),
//         Provider<AlertsService>(
//           create: (context) => AlertsService(context.read<FirebaseService>()),
//         ),
//         Provider<AlertsRepository>(
//           create: (context) => AlertsRepository(context.read<AlertsService>()),
//         ),
//         ChangeNotifierProvider(
//           create: (context) => AlertsViewModel(context.read<AlertsRepository>()),
//         ),
//         Provider<WiFiService>(
//           create: (context) => WiFiService(),
//         ),
//         ChangeNotifierProvider(
//           create: (context) => ProfileViewModel(context.read<AuthViewModel>()),
//         ),
//         Provider<NotificationService>.value(value: notificationService),
//       ],
//       child: MaterialApp(
//         title: 'AgriFeed Solar',
//         debugShowCheckedModeBanner: false,
//         theme: AppTheme.lightTheme,
//         home: const RootView(),
//       ),
//     );
//   }
// }

// class RootView extends StatelessWidget {
//   const RootView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthViewModel>(
//       builder: (context, authViewModel, _) {
//         switch (authViewModel.status) {
//           case AuthStatus.checking:
//             return const SplashView();
//           case AuthStatus.unauthenticated:
//             return const SignInView();
//           case AuthStatus.authenticated:
//             return const AppShell();
//         }
//       },
//     );
//   }
// }

// class AppShell extends StatefulWidget {
//   const AppShell({super.key});

//   @override
//   State<AppShell> createState() => _AppShellState();
// }

// class _AppShellState extends State<AppShell> {
//   int _currentIndex = 0;

//   final List<Widget> _pages = const [
//     DashboardView(),
//     FeedingView(),
//     AlertsView(),
//     ProfileView(),
//   ];

//   static const List<String> _titles = [
//     'Dashboard',
//     'Feeding Control',
//     'Alerts & Logs',
//     'Profile',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_titles[_currentIndex]),
//       ),
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _pages,
//       ),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _currentIndex,
//         height: 72,
//         onDestinationSelected: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home_outlined),
//             selectedIcon: Icon(Icons.home_rounded),
//             label: 'Home',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.rice_bowl_outlined),
//             selectedIcon: Icon(Icons.rice_bowl),
//             label: 'Feeding',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.notifications_none),
//             selectedIcon: Icon(Icons.notifications_active),
//             label: 'Alerts',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.person_outline),
//             selectedIcon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }
