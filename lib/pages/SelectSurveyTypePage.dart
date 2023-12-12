import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../appconfig/appUrls.dart';
import './ViewOnMapPolylinesPage.dart';
import './SurveyByTap.dart';
import './SurveyByWalk.dart';
import './SurveyByTapPolyline.dart';
import './ViewOnMapPage.dart';
import './ViewList.dart';
import './MainCategoriesPage.dart';
import './SubCategoriesPage.dart';
import './SettingsPage.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'DownloadDataPage.dart';
import './LoginPage.dart';
import 'package:url_launcher/url_launcher.dart';

class SelectSurveyTypePage extends StatefulWidget {
  User user;
  SelectSurveyTypePage(this.user);
  String title = "SELECT MODULE";

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SelectSurveyTypePageState();
  }
}

class _SelectSurveyTypePageState extends State<SelectSurveyTypePage> {
  final gridTextYellowStyle = TextStyle().copyWith(
      fontSize: 17.0, color: Color(0xff9B6E29), fontWeight: FontWeight.normal);
  final gridTextGreenStyle = TextStyle().copyWith(
      fontSize: 17.0, color: Color(0xff38A84F), fontWeight: FontWeight.normal);
  final gridTextBlueStyle = TextStyle().copyWith(
      fontSize: 17.0, color: Color(0xff22AEC7), fontWeight: FontWeight.normal);
  final gridTextPurpleStyle = TextStyle().copyWith(
      fontSize: 17.0, color: Color(0xffB15DF5), fontWeight: FontWeight.normal);
  final titleTextStyle = TextStyle().copyWith(
      fontSize: 19.0, color: Color(0xff262626), fontWeight: FontWeight.bold);
  static final double gridIconSize = 40.0;
  static final Color gridIconColor = Colors.white;
  static final Color cardColorYellow = Color(0xFFFCF8DD);
  static final Color cardColorGreen = Color(0xFFE7F4EA);
  static final Color cardColorPurple = Color(0xFFF4E8FE);
  static final Color cardColorBlue = Color(0xFFE4F7FB);

  static final Color iconColorYellow = Color(0xff9B6E29);
  static final Color iconColorBlue = Color(0xff22AEC7);
  static final Color iconColorPurple = Color(0xffB15DF5);
  static final Color iconColorGreen = Color(0xff38A84F);

  final Widget tapIcon = SvgPicture.asset(
    'assets/svgs/tap_icon.svg',
    semanticsLabel: 'Tap Icon',
    color: iconColorYellow,
  );
  final Widget walkIcon = SvgPicture.asset(
    'assets/svgs/walk_icon.svg',
    semanticsLabel: 'Walk Icon',
    color: iconColorGreen,
  );
  final Widget listIcon = SvgPicture.asset(
    'assets/svgs/list_icon.svg',
    semanticsLabel: 'List Icon',
    color: iconColorBlue,
  );
  final Widget compassIcon = SvgPicture.asset(
    'assets/svgs/compass_icon.svg',
    semanticsLabel: 'Compass Icon',
    color: iconColorPurple,
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late ServiceStatus _serviceStatus;
  late AndroidIntent intent;

  Future<bool> isInternetConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> checkLocationStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future openLocationSettings() async {
    if (Platform.isAndroid) {
      intent = AndroidIntent(
        action: 'action_location_source_settings',
      );
      await intent.launch();
    } else {
      // do for ios here
    }
    print("============location setting intent done====================");
  }

  Future showMessageDialog(String title, String content, [String? flag]) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(title),
              content: Text(
                content,
                style: TextStyle(fontSize: 13),
              ),
              actions: <Widget>[
                MaterialButton(
                  child: Text("Okay"),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (flag == "open_location_settings")
                      await openLocationSettings();
                  },
                )
              ]);
        });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();

    await _auth.signOut();

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
      return LoginPage();
    }), (route) => false);
   
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double screenWidth = size.width / 2;
    final double screenHeight = size.height / 2 - 40;
    Color cardColor = Color(0xFFF4FBFA);

    // TODO: implement build
    return MaterialApp(
      theme: ThemeData(
          primaryColorDark: Colors.teal[900],
          primaryColor: Color(0xff206a5d),
          cardColor: Color(0xFFF4FBFA),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal)
              .copyWith(secondary: Colors.tealAccent[400])
          ),
      home: Scaffold(
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Image.asset(
                      "assets/logo.jpg",
                      height: 70,
                    ),
                    Text(
                      "Survey App",
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    InkWell(
                      onTap: () async {
                        if (await isInternetConnected()) {
                          if (!await launchUrl(
                            Uri.parse('${AppUrls.website}'),
                            mode: LaunchMode.externalApplication,
                          )) {
                            throw Exception(
                                'Could not launch ${AppUrls.website}');
                          }
                        } else {
                          showMessageDialog(
                              "No Connection", "Internet connection required");
                        }
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${AppUrls.website}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Icon(
                              Icons.open_in_browser,
                              color: Colors.white,
                            )
                          ]),
                    )
                  ],
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ListTile(
                title: Text("SURVEY NAMES"),
                onTap: () async {
                  // open page for listing main categories
                  if (await isInternetConnected()) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return MainCategoriesPage(widget.user);
                    }));
                  } else {
                    showMessageDialog(
                        "No Connection", "Internet connection required");
                  }
                },
              ),
              Divider(
                height: 1.0,
              ),
              ListTile(
                title: Text("CLASS NAMES"),
                onTap: () async {
                  // open page for listing sub categories
                  if (await isInternetConnected()) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SubCategoriesPage(widget.user);
                    }));
                  } else {
                    showMessageDialog(
                        "No Connection", "Internet connection required");
                  }
                },
              ),
              Divider(
                height: 1.0,
              ),
              ListTile(
                title: Text("DOWNLOAD DATA"),
                onTap: () async {
                  if (await isInternetConnected()) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return DownloadDataPage(widget.user);
                    }));
                  } else {
                    showMessageDialog(
                        "No Connection", "Internet connection required");
                  }
                },
              ),
              Divider(
                height: 1.0,
              ),
              ListTile(
                title: Text("LOG OUT"),
                onTap: () {
                  signOut();
                },
              )
            ],
          ),
        ),
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            InkWell(
              onTap: () {
                showMessageDialog("Processing of Data",
                    "You can process and update the data on our official website. To get started, download your data from the app and upload it to our website for further processing. Once the upload is complete, you will be able to access the data and begin working with.");
              },
              child: Icon(Icons.info),
            ),
            SizedBox(
              width: 5,
            ),
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: InkWell(
                child: Icon(Icons.settings_outlined),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SettingsPage()));
                },
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
          padding: EdgeInsets.all(4.0),
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: 5.0,
                ),
                width: size.width,
                padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                child: Text(
                  "AREA SURVEY",
                  style: titleTextStyle,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        isInternetConnected().then((connected) {
                          if (connected) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SurveyByTap(widget.user)));
                          } else {
                            showMessageDialog("No Connection",
                                "Internet connection required before proceeding");
                          }
                        });
                      },
                      child: Card(
                        elevation: 3.0,
                        color: cardColorYellow,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                height: 20.0,
                              ),
                              tapIcon,
                          
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "Survey By \n Tap",
                                  style: gridTextYellowStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        isInternetConnected().then((connected) {
                          if (connected) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SurveyByWalk(widget.user)));
                          } else {
                            showMessageDialog("No Connection",
                                "Internet connection required before proceeding");
                          }
                        });
                      },
                      child: Card(
                        elevation: 3.0,
                        color: cardColorGreen,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                height: 20.0,
                              ),
                              walkIcon,
                             
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "Survey by \n Walk",
                                  style: gridTextGreenStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        isInternetConnected().then((connected) {
                          if (connected) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ViewOnMapPage(widget.user)));
                          } else {
                            showMessageDialog("No Connection",
                                "Internet connection required before proceeding");
                          }
                        });
                      },
                      child: Card(
                        elevation: 3.0,
                        color: cardColorPurple,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                height: 20,
                              ),
                              compassIcon,
                             
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "View Data \n on Map",
                                  style: gridTextPurpleStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        isInternetConnected().then((connected) {
                          if (connected) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ViewList(widget.user)));
                          } else {
                            showMessageDialog("No Connection",
                                "Internet connection required before proceeding");
                          }
                        });
                      },
                      child: Card(
                        elevation: 3.0,
                        color: cardColorBlue,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                height: 20,
                              ),
                              listIcon,
                             
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "View Data \n as List",
                                  style: gridTextBlueStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5.0),
                width: size.width,
                padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                child: Text("POLYLINE SURVEY", style: titleTextStyle),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        isInternetConnected().then((connected) {
                          if (connected) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SurveyByTapPolyline(widget.user)));
                          } else {
                            showMessageDialog("No Connection",
                                "Internet connection required before proceeding");
                          }
                        });
                      },
                      child: Card(
                        elevation: 3.0,
                        color: cardColorYellow,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                height: 20.0,
                              ),
                              tapIcon,
                             
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "Survey By \n Tap",
                                  style: gridTextYellowStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        isInternetConnected().then((connected) {
                          if (connected) {
                            checkLocationStatus().then((locationOn) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ViewOnMapPolylinesPage(widget.user)));
                            });
                          } else {
                            showMessageDialog("No Connection",
                                "Internet connection required before proceeding");
                          }
                        });
                      },
                      child: Card(
                        elevation: 3.0,
                        color: cardColorPurple,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                height: 20.0,
                              ),
                              compassIcon,
                             
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "View Data \n On Map",
                                  style: gridTextPurpleStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        )),
      ),
    );
  }
}
