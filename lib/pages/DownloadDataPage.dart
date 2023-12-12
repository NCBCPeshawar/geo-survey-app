import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/retry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../appconfig/appUrls.dart';

class DownloadDataPage extends StatefulWidget {
  User user;
  DownloadDataPage(this.user);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _DownloadDataPageState();
  }
}

class _DownloadDataPageState extends State<DownloadDataPage> {
  FirebaseDatabase database = FirebaseDatabase();
  late DatabaseReference myUserRef;
  late DatabaseReference usersRef;
  late DatabaseReference dataRef;
  late DatabaseReference surveyNamesRef;
  late DatabaseReference categoryNamesRef;

  Color startButtonColor = Color(0xFFE7F4EA);
  Color cancelButtonColor = Color(0xFFFCF8DD);
  Color stopButtonColor = Color(0xFFF9E6E4);
  Color disabledButtonColor = Colors.grey;

  Color greenButtonTextColor = Color(0xff38A84F);
  Color yellowButtonTextColor = Color(0xff9B6E29);
  Color redButtonTextColor = Color(0xFFEA4435);

  Color cardColor = Color(0xFFF4FBFA);

  bool startButtonPressed = false;
  bool stopButtonPressed = false;
  bool cancelButtonPressed = false;

  bool startButtonEnabled = true;
  bool stopButtonEnabled = false;
  bool cancelButtonEnabled = false;

  bool showDataBox = false;

  int polygonId = 0;

  List<DropdownMenuItem<String>> dropDownMenuItems = [];
  List<DropdownMenuItem<String>> catDropDownMenuItems = [];
  String selectedSurvey = "";
  String selectedCategory = "";
  String fieldName = "";
  String area = "";
  String documentId = "";
  String selectedData = "";
  Map<String, String> mapSurveyNames = Map<String, String>();
  Map<String, String> mapCategoryNames = Map<String, String>();
  List<String> listSurveyNames = [];
  List<String> listSelectedSurveyNames = [];
  List<bool> listCheckValues = [];
  List<String> listCategoryNames = [];

  void setFirebaseSettings() {
   
    dataRef = database.reference().child("data");
    usersRef = database.reference().child("users");

    myUserRef = dataRef.child(widget.user.uid);
    surveyNamesRef = usersRef.child(widget.user.uid).child("surveynames");
    categoryNamesRef = usersRef.child(widget.user.uid).child("categorynames");
  }

  void getFirebaseData() {
    surveyNamesRef.once().then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value == null) {
        print(" ======================= snapshots is null");
        mapSurveyNames["0"] = "mysurvey";
        setState(() {
          listSurveyNames.add("mysurvey");
          listCheckValues.add(false);
        });
        surveyNamesRef.update(mapSurveyNames);
        setSelectSurveyDropDownList();
      } else {
        setSelectSurveyDropDownList(snapshot.snapshot);
      }
    });
  }

  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();

    return directory!.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$selectedSurvey-$selectedCategory-polygons.json');
  }

  Future<void> getSurveyData() async {
    selectedData = '{ "${widget.user.uid}" : {';
    int counter = 0;

    String userIdToken = await widget.user.getIdToken();
    print("user id token = $userIdToken");
    listSelectedSurveyNames.forEach((element) async {
      final client = RetryClient(http.Client());
      try {
        final response = await client.get(Uri.parse(AppUrls.dataNode +
            '${widget.user.uid}/$element/.json?auth=${userIdToken}'));

        if (response.statusCode == 200) {
          counter++;
          selectedData = selectedData + '"$element" : ';
          selectedData = selectedData + response.body.toString();
          print(listSelectedSurveyNames.length.toString() +
              " " +
              counter.toString());
          if (listSelectedSurveyNames.length == counter) {
            selectedData = selectedData + " } }";
            print("========== done ================");
            shareFile(selectedData);
          } else {
            selectedData = selectedData + ",";
          }
        } else {
          print('status code ${response.statusCode}');
        }
      } catch (e) {
        throw Exception(e);
      } finally {
        client.close();
      }
    });
  }

  Future<void> shareFile(String selectedData) async {
    final file = await _localFile;
    await file.writeAsString(selectedData);
    Share.file(
        DateTime.now().millisecondsSinceEpoch.toString(),
        "${DateTime.now().millisecondsSinceEpoch.toString()}.json",
        await file.readAsBytes(),
        "application/json");
  }

  Future showMessageDialog(String title, String content) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              backgroundColor: cardColor,
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

  Future showExitDialog(String title, String content) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              backgroundColor: cardColor,
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                MaterialButton(
                  child: Text("Exit"),
                  onPressed: () {
                    exit(0);
                  },
                )
              ]);
        });
  }

  void setSelectSurveyDropDownList([DataSnapshot? snapshot]) {
    if (snapshot == null) {
      dropDownMenuItems = buildSelectSurveyDropDownMenuItems();
      setState(() {
        selectedSurvey = dropDownMenuItems[0].value!;
      });
      return;
    }
    List<dynamic> list = snapshot.value as List;
    setState(() {
      list.forEach((f) {
        listSurveyNames.add(f.toString());
        listCheckValues.add(false);
      });
    });

    dropDownMenuItems = buildSelectSurveyDropDownMenuItems();
    setState(() {
      selectedSurvey = dropDownMenuItems[0].value!;
    });
  }

  List<DropdownMenuItem<String>> buildSelectSurveyDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = [];
    listSurveyNames.forEach((sl) {
      items.add(DropdownMenuItem(
        value: sl.toString(),
        child: Text(sl.toString()),
      ));
    });
    return items;
  }

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

  void startProcesses() async {
    setFirebaseSettings();
    getFirebaseData();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startProcesses();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text("DOWNLOAD SURVEYS DATA"),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'downloadbtn',
          onPressed: () async {
            if (await isInternetConnected()) {
              getSurveyData();
            } else {
              showMessageDialog(
                  "No Connection", "Internet connection required");
            }
          },
          child: Icon(
            Icons.download_sharp,
            color: Colors.white,
          ),
        ),
        body: listSurveyNames.isEmpty
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.separated(
                separatorBuilder: (context, i) {
                  return Divider(
                    height: 1.0,
                  );
                },
                itemBuilder: (context, i) {
                  return CheckboxListTile(
                    title: Text(listSurveyNames[i].toString()),
                    onChanged: (bool? value) {
                      setState(() {
                        listCheckValues[i] = value!;
                      });
                      if (value!) {
                        listSelectedSurveyNames.add(listSurveyNames[i]);
                      } else {
                        listSelectedSurveyNames.remove(listSurveyNames[i]);
                      }
                      print(listSelectedSurveyNames.toString());
                    },
                    value: listCheckValues[i],
                    controlAffinity: ListTileControlAffinity.platform,
                  );
                },
                itemCount: listSurveyNames.length,
              ));
  }
}
