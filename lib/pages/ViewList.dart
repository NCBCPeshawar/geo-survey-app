import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/Userdatamodel.dart';
import '../MyUtils/AreaUnitUtils.dart';
import '../MyUtils/SharedPrefUtils.dart';

class ViewList extends StatefulWidget {
  User user;
  ViewList(this.user);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ViewListState();
  }
}

class _ViewListState extends State<ViewList> {
  late GoogleMapController mapController;

  SharedPrefUtils sharedPrefUtils = new SharedPrefUtils();

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
  Color silverTextColor = Color(0xFFA0A0A0);

  Color cardColor = Color(0xFFF4FBFA);

  bool _getting_location = false;
  static const timeout = const Duration(seconds: 40);
  static const ms = const Duration(milliseconds: 1);

  bool startButtonPressed = false;
  bool stopButtonPressed = false;
  bool cancelButtonPressed = false;

  bool startButtonEnabled = true;
  bool stopButtonEnabled = false;
  bool cancelButtonEnabled = false;

  bool showDataBox = false;

  int polygonId = 0;

  Set<Polygon> _setPolygons = Set();

  List<DropdownMenuItem<String>> dropDownMenuItems = [];
  List<DropdownMenuItem<String>> catDropDownMenuItems = [];
  String selectedSurvey = "";
  String selectedCategory = "";
  String fieldName = "";
  String area = "";
  String documentId = "";
  Map<String, String> mapSurveyNames = Map<String, String>();
  Map<String, String> mapCategoryNames = Map<String, String>();
  List<String> listSurveyNames = [];
  List<String> listCategoryNames = [];
  List<PolygonDataModelMap> polygons = [];
  late int areaUnitPref;

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
        mapSurveyNames["0"] = "mysurvey";
        setState(() {
          listSurveyNames.add("mysurvey");
        });
        surveyNamesRef.update(mapSurveyNames);
        setSelectSurveyDropDownList();
      } else {
        setSelectSurveyDropDownList(snapshot.snapshot);
      }
    });
    categoryNamesRef.once().then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value == null) {
        mapCategoryNames["0"] = "random";
        setState(() {
          listCategoryNames.add("random");
        });
        categoryNamesRef.set(mapCategoryNames);
        setSelectCategoryDropDownList();
      } else {
        setSelectCategoryDropDownList(snapshot.snapshot);
      }
    });

   
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

  Future showExitDialog(String title, String content) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
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

  void onViewPolygonsClick() {
    CategoryDataModel categoryDataModel;
    print("$selectedSurvey > $selectedCategory");
    myUserRef
        .child("$selectedSurvey/$selectedCategory/polygons")
        .once()
        .then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value == null) {
        // polygons does not exist of this category, means that category also doesnot exist
        setState(() {
          polygons = [];
        });
        showMessageDialog("Not Found", "Polygons not found for this category");
        return;
      }
      Map<dynamic, dynamic> map = snapshot.snapshot.value as Map;
      categoryDataModel = CategoryDataModel.setData(map);

      setState(() {
        polygons = categoryDataModel.polygons;
      });

    });
  }

  void createPolygons(List<PolygonDataModelMap> polygons) {
    _setPolygons.clear();
    List<LatLng> listLatLng = [];
    polygons.forEach((p) {
      setState(() {
        _setPolygons.add(new Polygon(
            polygonId: PolygonId(p.key),
            points: p.value.vertex.map((v) {
              List<String> latlng = v.split(",");
              // create list of markers of this polygon and add to main list of latlng
              listLatLng.add(
                  LatLng(double.parse(latlng[0]), double.parse(latlng[1])));
              return LatLng(double.parse(latlng[0]), double.parse(latlng[1]));
            }).toList(),
            fillColor: Color.fromARGB(125, 255, 0, 0),
            strokeWidth: 2,
            strokeColor: Colors.red,
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                showDataBox = true;
                documentId = p.key;
                fieldName = p.value.name;
                area = p.value.area.toString();
              });
            }));
      });

      polygonId = polygonId + 1;
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
      });
    });

    dropDownMenuItems = buildSelectSurveyDropDownMenuItems();
    setState(() {
      selectedSurvey = dropDownMenuItems[0].value!;
    });
  }

  void setSelectCategoryDropDownList([DataSnapshot? snapshot]) {
    if (snapshot == null) {
      catDropDownMenuItems = buildSelectCategoryDropDownMenuItems();
      setState(() {
        selectedCategory = catDropDownMenuItems[0].value!;
      });
      return;
    }
    List<dynamic> list = snapshot.value as List;
    setState(() {
      list.forEach((f) {
        listCategoryNames.add(f.toString());
      });
    });

    catDropDownMenuItems = buildSelectCategoryDropDownMenuItems();
    setState(() {
      selectedCategory = catDropDownMenuItems[0].value!;
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

  List<DropdownMenuItem<String>> buildSelectCategoryDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = [];
    listCategoryNames.forEach((sl) {
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

  void showConfirmCheckOutDialog(String title, String content, int i) {
    setState(() {
      // checkoutDialogBoxOpened = true;
    });
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: new Text(content),
            actions: <Widget>[
              new MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("No"),
              ),
              new MaterialButton(
                onPressed: () {
                  myUserRef
                      .child("$selectedSurvey/$selectedCategory/polygons/" +
                          polygons[i].key)
                      .remove()
                      .then((onValue) {
                    print("deleted.....");
                    setState(() {
                      polygons.removeAt(i);
                    });
                  });
                  Navigator.pop(context);
                },
                child: Text("Yes"),
              )
            ],
          );
        });
  }

  void startProcesses() async {
    await sharedPrefUtils.init();
    areaUnitPref = await sharedPrefUtils.getAreaUnitPref();
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
        title: Text("LIST OF POLYGONS"),
      ),
      body: selectedSurvey != "" && selectedCategory != ""
          ? Stack(
              children: <Widget>[
                polygons.length > 0
                    ? Container(
                        margin: EdgeInsets.fromLTRB(10, 0, 10, 210),
                        child: ListView.builder(
                          itemCount: polygons.length,
                          itemBuilder: (context, i) {
                            double area = polygons[i].value.area;
                            return Container(
                                decoration: BoxDecoration(
                                    color: Color(0xFFFFFCF9),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              Color.fromARGB(71, 102, 155, 188),
                                          blurRadius: 8,
                                          offset: Offset(4, 4),
                                          spreadRadius: 1)
                                    ]),
                                margin: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              polygons[i].value.name,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(AreaUnitUtils()
                                                .getAreaAsString(
                                                    area, areaUnitPref)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          InkWell(
                                              onTap: () {
                                                showConfirmCheckOutDialog(
                                                    "Confirmation",
                                                    "Do you really want to delete polygon?",
                                                    i);
                                              },
                                              child: Icon(
                                                Icons.delete,
                                                color: redButtonTextColor,
                                              )),
                                          Text(
                                            polygons[i].value.timeStamp.isEmpty
                                                ? ""
                                                : DateFormat.yMMMd().format(
                                                    DateTime.parse(polygons[i]
                                                        .value
                                                        .timeStamp)),
                                            style: TextStyle(
                                                color: silverTextColor),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ));
                          },
                        ),
                      )
                    : Center(
                        child: Container(
                          child: Text(
                            "In order to view data, use form below",
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ),
                      ),
                listSurveyNames.length > 0 && listCategoryNames.length > 0
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                              boxShadow: [
                                BoxShadow(
                                    color: Color.fromARGB(71, 102, 155, 188),
                                    blurRadius: 20,
                                    offset: Offset(0, -6),
                                    spreadRadius: 1)
                              ]),

                          margin: EdgeInsets.all(8.0),
                          width: MediaQuery.of(context).size.width,
                          height: 206.0,
                          padding: EdgeInsets.fromLTRB(10.0, 10, 0, 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Survey Name:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedSurvey,
                                  items: dropDownMenuItems,
                                  onChanged: (_) {
                                    setState(() {
                                      selectedSurvey = _!;
                                      print(
                                          "$selectedSurvey > $selectedCategory");
                                    });
                                  },
                                ),
                              ),
                              Text(
                                "Class Name:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedCategory,
                                  items: catDropDownMenuItems,
                                  onChanged: (_) {
                                    setState(() {
                                      selectedCategory = _!;
                                      print(
                                          "$selectedSurvey > $selectedCategory");
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: MaterialButton(
                                  child: Text(
                                    "View List",
                                    style:
                                        TextStyle(color: greenButtonTextColor),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  color: startButtonColor,
                                  onPressed: () {
                                    onViewPolygonsClick();
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    : Container(),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
