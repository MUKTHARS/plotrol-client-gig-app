import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/view/gig_views/gig_home_view.dart';
import 'package:plotrol/view/intro_screen.dart';
import 'package:plotrol/view/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'helper/api_constants.dart';
import 'model/response/autentication_response/autentication_response.dart';

// ⬇️ Replace these with your actual paths
 // <-- exposes checkIsGig / checkIsPGRAdmin

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  ApiConstants.login = ApiConstants.loginDev;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return GetMaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Future<_LaunchDecision> _decisionFuture;

  @override
  void initState() {
    super.initState();
    _decisionFuture = _getLaunchDecision();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LaunchDecision>(
      future: _decisionFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final decision = snap.data;

        if (decision == null || !decision.loggedIn) {
          return OnBoardPage();
        }

        final roles = decision.roles;
        final goGig = AppUtils().checkIsPGRAdmin(roles) || AppUtils().checkIsGig(roles);

        // DISTRIBUTOR (not PGR_ADMIN / HELPDESK_USER) -> HomeView
        // PGR admin or Gig roles -> GigHomeView
        return goGig ? GigHomeView(selectedIndex: 0,) : HomeView(selectedIndex: 0);
      },
    );
  }
}

class _LaunchDecision {
  final bool loggedIn;
  final List<Role> roles;
  const _LaunchDecision({required this.loggedIn, required this.roles});
}

Future<_LaunchDecision> _getLaunchDecision() async {
  final prefs = await SharedPreferences.getInstance();

  // if no token -> OnBoardPage
  final token = prefs.getString('access_token');
  if (token == null || token.isEmpty) {
    return const _LaunchDecision(loggedIn: false, roles: []);
  }

  // parse stored userInfo into List<Role>
  // you store it like: prefs.setString('userInfo', jsonEncode(result.userRequest?.toJson()));
  List<Role> roles = [];
  try {
    final raw = prefs.getString('userInfo');
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);

      // Expecting: decoded['roles'] is a List
      final dynamic rolesAny =
      decoded is Map<String, dynamic> ? decoded['roles'] : null;

      if (rolesAny is List) {
        roles = rolesAny
            .whereType<Map>() // ignore malformed entries
            .map((e) => Role.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
  } catch (_) {
    // swallow parsing errors; route with empty roles (will go HomeView)
  }

  return _LaunchDecision(loggedIn: true, roles: roles);
}
