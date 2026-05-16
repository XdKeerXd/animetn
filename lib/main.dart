import 'dart:async';
import 'dart:io';

import 'package:animetn/core/app/values.dart';
import 'package:app_links/app_links.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:animetn/core/anime/providers/animeonsen.dart';
import 'package:animetn/core/app/logging.dart';
import 'package:animetn/core/app/runtimeDatas.dart';
import 'package:animetn/core/app/version.dart';
import 'package:animetn/core/data/preferences.dart';
import 'package:animetn/core/data/settings.dart';
import 'package:animetn/core/data/theme.dart';
import 'package:animetn/ui/models/notification.dart';
import 'package:animetn/ui/models/providers/appProvider.dart';
import 'package:animetn/ui/models/providers/mainNavProvider.dart';
import 'package:animetn/ui/models/snackBar.dart';
import 'package:animetn/ui/models/sources.dart';
import 'package:animetn/ui/models/widgets/appWrapper.dart';
import 'package:animetn/ui/pages/info.dart';
import 'package:animetn/ui/pages/mainNav.dart';
import 'package:animetn/ui/theme/lime.dart';
import 'package:animetn/ui/theme/themes.dart';
import 'package:animetn/ui/theme/types.dart';
import 'package:fvp/fvp.dart' as fvp;

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..userAgent = AppValues.defaultClientUserAgent;
  }
}

void main(List<String> args) async {
  try {
    if (!kIsWeb && runWebViewTitleBarWidget(args)) {
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    // Initialise app version instance
    AppVersion.init();

    await Hive.initFlutter((!kIsWeb && defaultTargetPlatform != TargetPlatform.android) ? "animetn" : null);

    await loadAndAssignSettings();

    if (!kIsWeb) {
      fvp.registerWith(options: { 'platforms': ['linux', 'windows' ]});
    }

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
      await windowManager.ensureInitialized();
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);

      // No frameless for now!
      // if (currentUserSettings?.useFramelessWindow ?? true) await windowManager.setAsFrameless();

      await windowManager.setResizable(true);
    }

    AnimeOnsen().checkAndUpdateToken();

    NotificationService().init();

    /// Load sources. we adding inbuilt sources till migrated
    final sm = SourceManager.instance;

    sm
      ..addSources(sm.inbuiltSources)
      ..loadProviders(clearBeforeLoading: false);

    if (!kIsWeb) {
      HttpOverrides.global = _HttpOverrides();
    }

    // await dotenv.load(fileName: ".env");

    // if (currentUserSettings?.enableDiscordPresence ?? false) {
    //   await FlutterDiscordRPC.initialize("1362858832266657812");
    // }

    // FlutterError.onError = (FlutterErrorDetails details) async {
    //   FlutterError.presentError(details);

    //   // force add these error to logs
    //   Logs.app.log(details.exceptionAsString() + "\n${details.stack.toString()}", addToBuffer: true);
    //   await Logs.writeAllLogs();

    //   print("[ERROR] logged the error to logs folder");
    // };

    runApp(
      ChangeNotifierProvider(
        create: (context) => AppProvider(),
        child: const Animetn(),
      ),
    );
  } catch (err) {
    // These are critical errors, so we force log them
    Logs.app.log(err.toString(), addToBuffer: true);
    Logs.app.log("state: Crashed", addToBuffer: true);
    await Logs.writeAllLogs();

    print("[CRASH] logged the error to logs folder");
    rethrow;
  }
}

Future<void> loadAndAssignSettings() async {
  await Settings().getSettings().then((settings) => {
        currentUserSettings = settings,
        Logs.app.log("[STARTUP] Loaded user settings"),
      });

  await UserPreferences.getUserPreferences().then((pref) {
    userPreferences = pref;
    Logs.app.log("[STARTUP] Loaded user preferences");
  });

  //load and apply theme
  await getTheme().then((themeId) {
    // ignore the themeid limit checks for debug mode
    if ((themeId > availableThemes.length && !kDebugMode) || themeId < 1) {
      Logs.app.log("[STARTUP] Failed to apply theme with ID $themeId, Applying default theme");
      showToast("Failed to apply theme. Using default theme");
      setTheme(01);
      themeId = 01;
    }

    final darkMode = currentUserSettings!.darkMode!;

    ThemeItem? theme = availableThemes.where((theme) => theme.id == themeId).toList().firstOrNull;

    if (theme == null) {
      // Set default theme incase of any corruptions/issues n stuff
      theme = LimeZest();
      Logs.app.log("[STARTUP] Failed to apply theme with ID $themeId, Applying default theme");
    }

    if (darkMode) {
      appTheme = theme.theme;
      appTheme.backgroundColor =
          (currentUserSettings!.amoledBackground ?? false) ? Colors.black : theme.theme.backgroundColor;
    } else {
      appTheme = AnimetnTheme(
        accentColor: theme.lightVariant.accentColor,
        textMainColor: theme.lightVariant.textMainColor,
        textSubColor: theme.lightVariant.textSubColor,
        backgroundColor: theme.lightVariant.backgroundColor,
        backgroundSubColor: theme.lightVariant.backgroundSubColor,
        modalSheetBackgroundColor: theme.lightVariant.modalSheetBackgroundColor,
        onAccent: theme.lightVariant.onAccent,
      );
    }

    Logs.app.log("[STARTUP] Loaded theme of ID $themeId (${theme.name})");
  });
}

class Animetn extends StatefulWidget {
  const Animetn({super.key});

  static final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

  static final navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<Animetn> createState() => _AnimetnState();
}

class _AnimetnState extends State<Animetn> {
  StreamSubscription<Uri>? _sub;
  late AppLinks _appLinks;

  @override
  void initState() {
    listenDeepLinkCall();

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black.withValues(alpha: 0.002),
        systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
      ),
    );

    // if (currentUserSettings?.enableDiscordPresence ?? false)
    // FlutterDiscordRPC.instance.connect(autoRetry: true, retryDelay: Duration(seconds: 10));

    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();

    // if (currentUserSettings?.enableDiscordPresence ?? false) {
    //   FlutterDiscordRPC.instance.clearActivity();
    //   FlutterDiscordRPC.instance.disconnect();
    //   FlutterDiscordRPC.instance.dispose();
    // }
    super.dispose();
  }

  void listenDeepLinkCall() {
    _appLinks = AppLinks();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == "astrm") {
        Logs.app.log("Invoked DeepLink uri: ${uri.toString()}");
        String host = uri.host;
        switch (host) {
          case "info":
            {
              final id = int.tryParse(uri.queryParameters['id'] ?? "nothing");
              if (id != null) {
                Animetn.navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => AppWrapper(
                          firstPage: Info(id: id),
                        ),
                      ),
                    ) ??
                    print("Nah");
                break;
              }
            }
          default:
            floatingSnackBar("BAD-DEEPLINK: Host $host not recognized!");
        }
      }
    });
  }

  // This widget is the root of *my* application.
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: (currentUserSettings?.darkMode ?? true) ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.black.withValues(alpha: 0.002),
        systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
      ),
      child: DynamicColorBuilder(
        builder: (lightScheme, darkScheme) {
          late AnimetnTheme scheme;

          //just checks for dark mode and sets the appTheme variable with suitable theme
          if (currentUserSettings?.darkMode ?? true) {
            scheme = AnimetnTheme(
              accentColor: darkScheme?.primary ?? appTheme.accentColor,
              backgroundColor: (currentUserSettings?.amoledBackground ?? false)
                  ? Colors.black
                  : darkScheme?.surface ?? appTheme.backgroundColor,
              backgroundSubColor: darkScheme?.secondaryContainer ?? appTheme.backgroundSubColor,
              textMainColor: darkScheme?.onSurface ?? appTheme.textMainColor,
              textSubColor: darkScheme?.onSurfaceVariant ?? appTheme.textSubColor,
              modalSheetBackgroundColor: darkScheme?.surface ?? appTheme.modalSheetBackgroundColor,
              onAccent: darkScheme?.onPrimary ?? appTheme.onAccent,
            );
          } else {
            scheme = AnimetnTheme(
              accentColor: lightScheme?.primary ?? appTheme.accentColor,
              backgroundColor: lightScheme?.surface ?? appTheme.accentColor,
              backgroundSubColor: lightScheme?.secondaryContainer ?? appTheme.backgroundSubColor,
              textMainColor: lightScheme?.onSurface ?? appTheme.textMainColor,
              textSubColor: lightScheme?.onSurfaceVariant ?? appTheme.textSubColor,
              modalSheetBackgroundColor: lightScheme?.surface ?? appTheme.modalSheetBackgroundColor,
              onAccent: lightScheme?.onPrimary ?? appTheme.onAccent,
            );
          }

          if (currentUserSettings?.materialTheme ?? false) {
            appTheme = scheme;
            // print("[THEME] Applying Material You Theme");
          } else {
            // lmao we can make it follow material theme XD
            // final t = ThemeData.from(
            //   colorScheme: ColorScheme.fromSeed(
            //       seedColor: appTheme.accentColor,
            //       brightness: (currentUserSettings?.darkMode ?? true) ? Brightness.dark : Brightness.light),
            // ).colorScheme;
            // appTheme = AnimetnTheme(
            //   accentColor: t.primary,
            //   backgroundColor: t.surface,
            //   backgroundSubColor: t.secondaryContainer,
            //   textMainColor: t.onSurface,
            //   textSubColor: t.outline,
            //   modalSheetBackgroundColor: t.surface,
            //   onAccent: t.onPrimary,
            // );
          }

          final themeProvider = Provider.of<AppProvider>(context);

          return MaterialApp(
            title: 'Animetn',
            navigatorKey: Animetn.navigatorKey,
            scaffoldMessengerKey: Animetn.snackbarKey,
            theme: ThemeData(
                useMaterial3: true,
                brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
                textTheme: Theme.of(context).textTheme.apply(bodyColor: appTheme.textMainColor, fontFamily: "NotoSans"),
                scaffoldBackgroundColor: appTheme.backgroundColor,
                bottomSheetTheme: BottomSheetThemeData(backgroundColor: appTheme.modalSheetBackgroundColor),
                colorScheme: ColorScheme.fromSeed(
                  brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
                  seedColor: (currentUserSettings?.materialTheme ?? false) ? scheme.accentColor : appTheme.accentColor,
                ),
                iconTheme: IconThemeData(color: appTheme.textMainColor)),
            home: ChangeNotifierProvider(
              create: (context) => MainNavProvider(),
              child: (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) ? AppWrapper(firstPage: MainNavigator()) : MainNavigator(),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
