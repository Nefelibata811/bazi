import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_colors.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/collection/presentation/pages/collection_page.dart';
import '../features/history/presentation/pages/people_list_page.dart';
import '../features/input/presentation/pages/home_input_page.dart';
import 'theme/app_theme.dart';

class BaziApp extends StatelessWidget {
  const BaziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _BaziAppView(),
    );
  }
}

class _BaziAppView extends ConsumerWidget {
  const _BaziAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: '八字排盘',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.loading
          ? const _SplashView()
          : authState.needsPasswordReset
              ? const ResetPasswordPage()
              : authState.isLoggedIn
                  ? const PeopleListPage()
                  : const LoginPage(),
      initialRoute: authState.loading
          ? null
          : authState.needsPasswordReset
              ? '/reset_password'
              : authState.isLoggedIn
                  ? '/home'
                  : '/login',
      onGenerateRoute: (settings) {
        final state = ref.read(authControllerProvider);
        final isLoggedIn = state.isLoggedIn;
        final needsPwReset = state.needsPasswordReset;
        const authPages = ['/login', '/register', '/reset_password'];

        if (needsPwReset && settings.name != '/reset_password') {
          return _slideRoute(const ResetPasswordPage(), settings);
        }

        if (!isLoggedIn && !authPages.contains(settings.name) && !needsPwReset) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
            settings: settings,
          );
        }

        if (isLoggedIn && authPages.contains(settings.name)) {
          return MaterialPageRoute(
            builder: (_) => const PeopleListPage(),
            settings: settings,
          );
        }

        switch (settings.name) {
          case '/login':
            return _slideRoute(const LoginPage(), settings);
          case '/register':
            return _slideRoute(const RegisterPage(), settings);
          case '/reset_password':
            return _slideRoute(const ResetPasswordPage(), settings);
          case '/home':
            return _slideRoute(const PeopleListPage(), settings);
          case '/input':
            return _slideRoute(const HomeInputPage(), settings);
          case '/profile':
            return _slideRoute(const ProfilePage(), settings);
          case '/collections':
            return _slideRoute(const CollectionPage(), settings);
          case '/collection_detail':
            final args = settings.arguments as Map<String, dynamic>?;
            return _slideRoute(
              CollectionDetailPage(
                collectionId: args?['collectionId'] as String,
                collectionName: args?['collectionName'] as String,
              ),
              settings,
            );
          default:
            return _slideRoute(const PeopleListPage(), settings);
        }
      },
    );
  }

  PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('八  字', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(
              'B A Z I',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 6,
                    color: AppColors.deepGray,
                  ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
