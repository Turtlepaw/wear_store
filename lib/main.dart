import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:relative_time/relative_time.dart';
import 'package:wear_store/routes/editProfile.dart';
import 'package:wear_store/routes/home.dart';
import 'package:wear_store/routes/login_modal.dart';
import 'package:wear_store/routes/search.dart';
import 'package:wear_store/routes/settings.dart';
import 'package:wear_store/routes/user.dart';
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
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
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

CustomTransitionPage buildPageWithSmoothFadeSlideTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration:
        const Duration(milliseconds: 250), // Adjust duration for smoothness
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.01, 0.0); // Slight slide, mainly fade
      const end = Offset.zero;
      const curve =
          Curves.easeIn; // Smooth 'easeIn' curve for both slide and fade

      var slideTween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var slideAnimation = animation.drive(slideTween);

      var fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeIn, // Smooth fade-in
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation, // Slide is subtle
          child: child,
        ),
      );
    },
  );
}

Page<dynamic> Function(BuildContext, GoRouterState)
    defaultSmoothFadeSlidePageBuilder<T>(Widget child) =>
        (BuildContext context, GoRouterState state) {
          return buildPageWithSmoothFadeSlideTransition<T>(
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
            return defaultSmoothFadeSlidePageBuilder(
                WatchFace(id: state.pathParameters['id']))(context, state);
          }),
      GoRoute(
          path: '/user/:id',
          pageBuilder: (context, state) {
            return defaultPageBuilder(
                UserProfile(id: state.pathParameters['id']))(context, state);
          }),
      GoRoute(
          path: '/login', pageBuilder: defaultPageBuilder(const LoginDialog())),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => defaultSmoothFadeSlidePageBuilder(
            Search(
                text: state.uri.queryParameters['text'],
                tags: state.uri.queryParameters['tags']))(context, state),
      ),
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

  if (kIsWeb) usePathUrlStrategy();
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
  static final _defaultLightColorScheme = ColorScheme.fromSeed(
      seedColor: HexColor("#979dcc"), brightness: Brightness.light);

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
      seedColor: HexColor("#979dcc"), brightness: Brightness.dark);

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

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
