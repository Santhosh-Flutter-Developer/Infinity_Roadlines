import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/driver/home_screen.dart';
import 'screens/driver/lr_destination_list_screen.dart';
import 'screens/driver/lr_list_screen.dart';
import 'screens/driver/lr_detail_screen.dart';
import 'screens/driver/profile_screen.dart';
import 'screens/driver/trip_sheet_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/driver_detail_screen.dart';
import 'screens/admin/live_map_screen.dart';
import 'widgets/location_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authState.value;
      final loggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        if (user.role == 'driver') {
          return '/driver';
        } else if (user.role == 'admin') {
          return '/admin';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverHomeScreen(),
        routes: [
          GoRoute(
            path: 'sheet/:tripId',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return TripSheetScreen(tripId: tripId);
            },
          ),
          GoRoute(
            path: 'trips/:tripId',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return LrListScreen(tripId: tripId);
            },
            routes: [
              GoRoute(
                path: 'lrs/:lrId',
                builder: (context, state) {
                  final lrId = state.pathParameters['lrId']!;
                  return LrDetailScreen(lrId: lrId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const DriverProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'drivers/:driverId',
            builder: (context, state) {
              final driverId = state.pathParameters['driverId']!;
              return AdminDriverDetailScreen(driverUid: driverId);
            },
          ),
          GoRoute(
            path: 'map',
            builder: (context, state) => const AdminLiveMapScreen(),
          ),
        ],
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Trip Sheet Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: router,
      builder: (context, child) {
        return LocationGuard(child: child!);
      },
    );
  }
}
