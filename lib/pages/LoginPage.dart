import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import './SelectSurveyTypePage.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();

    print("User Sign Out");
  }

  Future<User> signInWithGoogle() async {
    final GoogleSignInAccount? googleSignInAccount =
        await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User user = authResult.user!;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final User currentUser = _auth.currentUser!;
    List<UserInfo> userInfo = currentUser.providerData;
    print("=====================");
    print(userInfo.toString());
    print("=====================");
    assert(user.uid == currentUser.uid);

    return user;
  }


  Future showMessageDialog(String title, String content) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                MaterialButton(
                  child: Text("Okay"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ]);
        });
  }

  Future startProcesses() async {


    if (_auth.currentUser != null) {
      Future.delayed(Duration(milliseconds: 100), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => SelectSurveyTypePage(_auth.currentUser!)),
            (Route<dynamic> route) => false);
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    startProcesses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/logo.jpg',
                width: 200,
              ),
              SizedBox(
                height: 50,
              ),
              signInButtonWidget("google"),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget signInButtonWidget(String buttonType) {
    return MaterialButton(
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
        side: BorderSide(color: Colors.white70),
      ),
      onPressed: () {
        buttonType == "google"
            ? signInWithGoogle().then((User user) {
                if (user != null) {
                  print("open page");
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SelectSurveyTypePage(user)),
                      (Route<dynamic> route) => false);
                }
              }).catchError((e) => print(e.toString()))
            : Container();
      
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          children: <Widget>[
            Image(
                height: 30,
                image: buttonType == "google"
                    ? AssetImage("assets/google_logo.png")
                    : buttonType == "facebook"
                        ? AssetImage("assets/facebook_logo.png")
                        : AssetImage('')),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                buttonType == "google"
                    ? "Sign in with Google"
                    : buttonType == "facebook"
                        ? "Sign in with Facebook"
                        : "",
                style: TextStyle(color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}
