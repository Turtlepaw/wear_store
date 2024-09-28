import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:relative_time/relative_time.dart';
import 'package:wear_store/routes/editProfile.dart';
import 'package:wear_store/routes/home.dart';
import 'package:wear_store/routes/login.dart';
import 'package:wear_store/routes/login_modal.dart';
import 'package:wear_store/routes/settings.dart';
import 'package:wear_store/routes/splash_screen.dart';
import 'package:wear_store/routes/watchface.dart';
import 'package:wear_store/utils/pocketbase.dart';
import 'package:wear_store/utils/wearManager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'components/navigation.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 50),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

Page<dynamic> Function(BuildContext, GoRouterState) defaultPageBuilder<T>(
        Widget child) =>
    (BuildContext context, GoRouterState state) {
      return buildPageWithDefaultTransition<T>(
        context: context,
        state: state,
        child: child,
      );
    };

final _router = GoRouter(
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    routes: [
      // GoRoute(
      //     path: '/',
      //     builder: (context, state) => SplashScreen(asyncFunction: () async {
      //           if (context.mounted) {
      //             var pb = Provider.of<PocketBase>(context, listen: false);
      //
      //             if (pb.authStore.isValid) {
      //               // User is logged in, navigate to home
      //               context.go('/home');
      //             } else {
      //               // User is not logged in, navigate to login
      //               context.go('/login');
      //             }
      //           }
      //         })),
      // GoRoute(
      //   path: '/login',
      //   pageBuilder: defaultPageBuilder(const LoginPage()),
      // ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: defaultPageBuilder(const ProfileDialog()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: defaultPageBuilder(const LoginDialog()),
      ),
      GoRoute(
          path: '/watchface/:id',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return defaultPageBuilder(
                WatchFace(id: state.pathParameters['id']))(context, state);
          }),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        pageBuilder: (context, state, child) {
          return NoTransitionPage(
              child: Scaffold(
            bottomNavigationBar: CustomNavigationBar(state: state),
            body: child,
          ));
        },
        routes: [
          GoRoute(pageBuilder: defaultPageBuilder(const Home()), path: '/home'),
          GoRoute(
            path: '/settings',
            pageBuilder: defaultPageBuilder(const SettingsPage()),
          )
        ],
      )
    ]);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pb = await initializePocketbase();
  final wearManager = WearManager(pb).sendAuthentication();

  runApp(
    MultiProvider(
      providers: [
        Provider<PocketBase>.value(
          value: pb,
        )
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.deepPurple, brightness: Brightness.dark);

  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp.router(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          RelativeTimeLocalizations.delegate
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('es'), // Spanish
        ],
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        title: 'Fitness Challenges',
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
          iconTheme: const IconThemeData(
              color: Colors.black, fill: 1, weight: 400, opticalSize: 24),
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
          iconTheme: const IconThemeData(
              color: Colors.white, fill: 1, weight: 400, opticalSize: 24),
        ),
        themeMode: ThemeMode.system,
      );
    });
  }
}
