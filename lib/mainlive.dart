import 'dart:io';

// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_app_version_checker/flutter_app_version_checker.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:plotrol/helper/api_constants.dart';
import 'package:plotrol/view/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'controller/network_controller.dart';
import 'helper/Logger.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// AndroidNotificationChannel channel = const AndroidNotificationChannel(
//   'Plotrol', // id
//   'Plotrol Notifications', // title
//   description: 'Plotrol', // description
//   importance: Importance.high,
//   sound: RawResourceAndroidNotificationSound('ring'),
//   enableLights: true,
//   enableVibration: true,
//   playSound: true,
//   showBadge: true,
//   // vibrationPattern:Int64List.fromList([500, 1000, 500]),
// );

// // final instance = FirebaseMessaging.instance;
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

void main() async {
  CheckInternetConnectivity.init();
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // IntialNotifcationSetting().init();
  ApiConstants.login = ApiConstants.loginLive;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return GetMaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          useMaterial3: true,
          primaryColor: Colors.white,
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
  // FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  String? uniqueDeviceId;
  String? deviceId;
  int? userId;
  String? userFcmToken;
  var iosDeviceInfo;
  var androidDeviceInfo;
  // final status = AppVersionChecker();

  @override
  void initState() {
    getUserDetails();
    // fcmToken();
    // getId();
    // LocalNotificationService.initialize(context);
    // checkVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    logger.i('UserID  : ${userId}');
    logger.i('USerFcmToken : ${userFcmToken}');
    return HomeView(
      selectedIndex: 0,
    );

    // (userId == null || userFcmToken == null)
    //   ? OnBoardPage()
    //   : HomeView(
    //       selectedIndex: 0,
    //     );
  }

  // Future<String?> getId() async {
  //   var deviceInfo = DeviceInfoPlugin();
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   if (Platform.isIOS) {
  //     iosDeviceInfo = await deviceInfo.iosInfo;
  //     deviceId = iosDeviceInfo.toMap().toString();
  //     uniqueDeviceId = iosDeviceInfo.id;
  //     prefs.setString('deviceId ', uniqueDeviceId!);
  //     print('iosDeviceInfodeviceId $deviceId');
  //     print('uniqueDeviceId ${prefs.getString('deviceId')}');
  //     // return iosDeviceInfo.identifierForVendor; // Unique ID on iOS
  //   } else {
  //     androidDeviceInfo = await deviceInfo.androidInfo;
  //     deviceId = androidDeviceInfo.toMap().toString();
  //     uniqueDeviceId = androidDeviceInfo.id;
  //     prefs.setString('deviceId', uniqueDeviceId!);
  //     print('androidDeviceInfodeviceId$deviceId');
  //     print('uniqueDeviceId${prefs.getString('deviceId')}');
  //   }
  //   return null;
  // }

  // fcmToken() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   firebaseMessaging.getToken().then((token) {
  //     print("firebasenotification1");
  //     print("firebse======$token");
  //     prefs.setString('fcmToken', token!);
  //     print("fcmtokeninauthenticate ${prefs.getString(
  //       'fcmToken',
  //     )}");
  //   });
  // }

  getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    userFcmToken = prefs.getString('userFcmToken');
    logger.i('UserId From UserDetails : $userId');
  }

// checkVersion() async {
//   status.checkUpdate().then((value) {
//     logger.i(
//         "canUpdateinversionchecker${value.canUpdate}"); //return true if update is available
//     logger.i(
//         "currentVersioninversionchecker${value.currentVersion}"); //return current app version
//     logger.i(
//         "newVersioninversionchecker${value.newVersion}"); //return the new app version
//     logger.i("appURLinversionchecker${value.appURL}"); //return the app url
//     logger.i(value.errorMessage);
//     if (value.canUpdate) {
//       Get.to(UpdateAppPage(
//         mCurrentVersion: value.currentVersion.toString(),
//         mUpdateVersion: value.newVersion.toString(),
//       ));
//     } //return error message if found else it will return null
//   });
// }
}

// class IntialNotifcationSetting {
//   var payload = {}.obs;
//   // final Int64List? vibrationPattern1 = Int64List(4);
//   // final Int64List? vibrationPattern2 = Int64List(3);
//
//   init() async {
//     var requestPermission = instance.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
// //     FirebaseMessaging.instance.getInitialMessage().then((message) async {
// //       if (message != null) {
// //         RemoteNotification notification = message.notification!;
// //         AndroidNotification? android = message.notification?.android;
// //         if (android != null) {
// //           flutterLocalNotificationsPlugin.show(
// //               notification.hashCode,
// //               notification.title,
// //               notification.body,
// //               const NotificationDetails(
// //                 android: AndroidNotificationDetails(
// //                   "Plotrol",
// //                   "Plotrol Client",
// //                   "hello everyone",
// //                   color: Colors.red,
// //                   playSound: true,
// //                   enableVibration: true,
// //                   //vibrationPattern: vibrationPattern1,
// //                   sound: RawResourceAndroidNotificationSound('ring'),
// //                   importance: Importance.high,
// //                   priority: Priority.high,
// //                   enableLights: true,
// //                   groupAlertBehavior: GroupAlertBehavior.all,
// //                 ),
// //                 iOS: IOSNotificationDetails(
// //                   presentSound: true,
// //                   presentAlert: true,
// //                   presentBadge: true,
// //                 ),
// //               ));
// //         }
// //       }
// //     });
// //
// //     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
// //       print("back");
// //       payload.value = message.data;
// //       print('payloadvaluesssssssss $payload');
// //       // showNotificationWithDefaultSound();
// //     });
// //
// // // Method 2
// //     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {});
// //
// //     // instance.getToken().then((String? token) {
// //     //   debugPrint("onToken: $token");
// //     // });
// //
// //     FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
// //       alert: true,
// //       sound: true,
// //       badge: true,
// //     );
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     if (Platform.isAndroid) {
//       String? token = await instance.getToken();
//       print("firebase token======$token");
//
//       prefs.setString('fcmToken', token ?? '');
//       print("tenanttokensetstring${prefs.getString('fcmToken')}");
//     } else if (Platform.isIOS || Platform.isMacOS) {
//       NotificationSettings settings = await instance.requestPermission();
//       String? token = await instance.getAPNSToken();
//       print("firebase Ios token====== $token");
//       if (token != null) {
//         prefs.setString('fcmToken', token ?? '');
//         print('ifprinttokenapns $token');
//       } else {
//         print('apnselse');
//         // Handle case where APNS token is null
//       }
//
//       print("Iostenanttokensetstring ${prefs.getString('fcmToken')}");
//     }
//   }
// }

/// To check the internet connectivity
class CheckInternetConnectivity {
  static void init() {
    Get.put<NetworkController>(NetworkController(), permanent: true);
  }
}
