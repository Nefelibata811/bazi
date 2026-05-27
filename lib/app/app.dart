// 根路由与主界面：登录态切换首页、命名路由、底部 Tab（命主列表 / AI 看盘）。
// _MainShell 使用 IndexedStack 保持 Tab 状态；navigateToHomeTab 用于回到主页。

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_colors.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/ai_chat/application/chat_controller.dart';
import '../features/ai_chat/presentation/pages/chat_page.dart';
import '../features/collection/presentation/pages/collection_page.dart';
import '../features/history/presentation/pages/chart_history_page.dart';
import '../features/history/application/bazi_records_list_controller.dart';
import '../features/history/application/collections_list_controller.dart';
import '../features/history/presentation/pages/people_list_page.dart';
import '../features/input/presentation/pages/home_input_page.dart';
import '../features/reverse_lookup/presentation/pages/reverse_lookup_page.dart';
import 'theme/app_theme.dart';
import 'widgets/app_splash.dart';

final mainTabIndexProvider = StateProvider<int>((ref) => 0);
final aiChatRefreshSignal = StateProvider<int>((ref) => 0);
final chatClearSignal = StateProvider<int>((ref) => 0);

/// 回到主页并切换 Tab，关闭叠在上面的排盘/录入等路由。
Future<void> navigateToHomeTab(
  BuildContext context,
  WidgetRef ref, {
  int tabIndex = 0,
}) async {
  ref.read(mainTabIndexProvider.notifier).state = tabIndex;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_tab_index', tabIndex);
    if (tabIndex != 1) {
      await prefs.setBool('pending_ai_auto_start', false);
    }
  } catch (_) {}
  if (context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class BaziApp extends StatelessWidget {
  const BaziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BaziAppView();
  }
}

class _BaziAppView extends ConsumerStatefulWidget {
  const _BaziAppView();

  @override
  ConsumerState<_BaziAppView> createState() => _BaziAppViewState();
}

class _BaziAppViewState extends ConsumerState<_BaziAppView> {
  @override
  Widget build(BuildContext context) {
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
          ? const AppSplash()
          : authState.needsPasswordReset
              ? const ResetPasswordPage()
              : authState.isLoggedIn
                  ? const _MainShell()
                  : authState.needsEmailConfirmation
                      ? const RegisterPage()
                      : const LoginPage(),
      onGenerateRoute: (settings) {
        final state = ref.read(authControllerProvider);
        final isLoggedIn = state.isLoggedIn;
        final needsPwReset = state.needsPasswordReset;
        const authPages = ['/login', '/register', '/reset_password'];

        if (needsPwReset && settings.name != '/reset_password') {
          return _slideRoute(const ResetPasswordPage(), settings);
        }

        if (!isLoggedIn &&
            !authPages.contains(settings.name) &&
            !needsPwReset) {
          if (state.needsEmailConfirmation) {
            return _slideRoute(const RegisterPage(), settings);
          }
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
            settings: settings,
          );
        }

        if (isLoggedIn && authPages.contains(settings.name)) {
          return _slideRoute(const _MainShell(), settings);
        }

        switch (settings.name) {
          case '/login':
            return _slideRoute(const LoginPage(), settings);
          case '/register':
            return _slideRoute(const RegisterPage(), settings);
          case '/reset_password':
            return _slideRoute(const ResetPasswordPage(), settings);
          case '/main':
          case '/home':
            return _slideRoute(const _MainShell(), settings);
          case '/input':
            return _slideRoute(const HomeInputPage(), settings);
          case '/reverse_lookup':
            return _slideRoute(const ReverseLookupPage(), settings);
          case '/profile':
            return _slideRoute(const ProfilePage(), settings);
          case '/history':
            return _slideRoute(const ChartHistoryPage(), settings);
          case '/collections':
            return _slideRoute(const CollectionPage(), settings);
          case '/collection_detail':
            final args = settings.arguments;
            if (args is! Map<String, dynamic>) {
              return _unknownRoute(settings);
            }
            final collectionId = args['collectionId'] as String?;
            final collectionName = args['collectionName'] as String?;
            if (collectionId == null || collectionName == null) {
              return _unknownRoute(settings);
            }
            return _slideRoute(
              CollectionDetailPage(
                collectionId: collectionId,
                collectionName: collectionName,
              ),
              settings,
            );
          default:
            return _unknownRoute(settings);
        }
      },
    );
  }

  MaterialPageRoute<void> _unknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const Scaffold(
        body: Center(child: Text('页面不存在')),
      ),
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

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  static const _tabKey = 'app_tab_index';

  @override
  void initState() {
    super.initState();
    _restoreTabIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 首帧后再拉列表，避免与登录恢复抢首屏时间
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        ref.read(baziRecordsListProvider.notifier).ensureLoaded();
        ref.read(collectionsListProvider.notifier).ensureLoaded();
      });
    });
  }

  Future<void> _restoreTabIndex() async {
    try {
      if (ref.read(mainTabIndexProvider) == 1) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('pending_ai_auto_start') == true) return;

      final saved = prefs.getInt(_tabKey);
      if (saved != null && mounted) {
        ref.read(mainTabIndexProvider.notifier).state = saved;
      }
    } catch (_) {}
  }

  int get _currentIndex => ref.watch(mainTabIndexProvider);

  void _onTabChanged(int index) {
    ref.read(mainTabIndexProvider.notifier).state = index;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_tabKey, index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (ref.read(mainTabIndexProvider) != 1) return;
        if (ref.read(chatControllerProvider).selectedRecordId != null) {
          ref.read(chatClearSignal.notifier).state++;
          return;
        }
        _onTabChanged(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            PeopleListPage(),
            ChatPage(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
            backgroundColor: AppColors.paper,
            selectedItemColor: AppColors.gold,
            unselectedItemColor: AppColors.deepGray,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: '主页',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: 'AI 看盘',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
