import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/alerts/repository/alerts_repository.dart';
import 'features/alerts/services/alerts_service.dart';
import 'features/alerts/view/alerts_view.dart';
import 'features/alerts/viewmodel/alerts_viewmodel.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/view/sign_in_view.dart';
import 'features/auth/view/splash_view.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/dashboard/repository/dashboard_repository.dart';
import 'features/dashboard/services/dashboard_service.dart';
import 'features/dashboard/view/dashboard_view.dart';
import 'features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'features/feeding/repository/feeding_repository.dart';
import 'features/feeding/services/feeding_service.dart';
import 'features/feeding/view/feeding_view.dart';
import 'features/feeding/viewmodel/feeding_viewmodel.dart';
import 'features/profile/view/profile_view.dart';
import 'features/profile/viewmodel/profile_viewmodel.dart';
import 'features/wifi/services/wifi_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message received: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
}

Future<void> setupFlutterNotifications() async {
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Android notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'agrifeed_channel', // id
    'AgriFeed Notifications', // name
    description: 'Notifications for Pig Feeder app',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // Create notification channel for Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation
          <AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // Handle notification tap
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('📱 Notification tapped: ${response.payload}');
      // Navigate to dashboard or specific screen
      if (response.payload != null) {
        navigatorKey.currentState?.pushReplacementNamed('/dashboard');
      }
    },
  );

  // Request permissions for iOS
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // Foreground notification presentation options
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message received: ${message.messageId}');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'] ?? '/dashboard',
      );
    }
  });

  // Handle notification tap when app is in background/terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📱 Notification opened app: ${message.messageId}');
    print('   Data: ${message.data}');
    
    // Navigate based on notification data
    final route = message.data['route'] ?? '/dashboard';
    navigatorKey.currentState?.pushReplacementNamed(route);
  });

  // Check if app was opened from a terminated state via notification
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('📱 App opened from terminated state via notification');
    print('   Data: ${initialMessage.data}');
  }

  print('✅ Push notifications configured');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize flutter local notifications + FCM
  await setupFlutterNotifications();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(AgriFeedSolarApp(notificationService: notificationService));
}

class AgriFeedSolarApp extends StatelessWidget {
  const AgriFeedSolarApp({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseService()),
        Provider<AuthService>(
          create: (context) => AuthService(context.read<FirebaseService>()),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepository(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(context.read<AuthRepository>()),
        ),
        Provider<DashboardService>(
          create: (context) =>
              DashboardService(context.read<FirebaseService>()),
        ),
        Provider<FeedingService>(
          create: (context) => FeedingService(context.read<FirebaseService>()),
        ),
        Provider<FeedingRepository>(
          create: (context) =>
              FeedingRepository(context.read<FeedingService>()),
        ),
        Provider<AlertsService>(
          create: (context) => AlertsService(context.read<FirebaseService>()),
        ),
        Provider<AlertsRepository>(
          create: (context) =>
              AlertsRepository(context.read<AlertsService>()),
        ),
        ProxyProvider3<DashboardService, FeedingRepository, AlertsRepository,
            DashboardRepository>(
          update: (context, dashboardService, feedingRepo, alertsRepo, _) =>
              DashboardRepository(
            dashboardService,
            feedingRepository: feedingRepo,
            alertsRepository: alertsRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              DashboardViewModel(context.read<DashboardRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AlertsViewModel(context.read<AlertsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              FeedingViewModel(
                context.read<FeedingRepository>(),
                context.read<AlertsViewModel>(),
              ),
        ),
        Provider<WiFiService>(
          create: (context) => WiFiService(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProfileViewModel(context.read<AuthViewModel>()),
        ),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: MaterialApp(
        title: 'AgriFeed Solar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey, // IMPORTANT: Add this
        home: const RootView(),
        routes: {
          '/dashboard': (context) => const AppShell(initialIndex: 0),
          '/feeding': (context) => const AppShell(initialIndex: 1),
          '/alerts': (context) => const AppShell(initialIndex: 2),
          '/profile': (context) => const AppShell(initialIndex: 3),
        },
      ),
    );
  }
}

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        switch (authViewModel.status) {
          case AuthStatus.checking:
            return const SplashView();
          case AuthStatus.unauthenticated:
            return const SignInView();
          case AuthStatus.authenticated:
            return const AppShell();
        }
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    DashboardView(),
    FeedingView(),
    AlertsView(),
    ProfileView(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'Feeding Control',
    'History & Logs', //Alerts & Logs
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 72,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.rice_bowl_outlined),
            selectedIcon: Icon(Icons.rice_bowl),
            label: 'Feeding',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}