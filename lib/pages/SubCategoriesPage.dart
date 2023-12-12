import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/Userdatamodel.dart';

class SubCategoriesPage extends StatefulWidget {
  User user;
  SubCategoriesPage(this.user);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SubCategoriesPageState();
  }
}

class _SubCategoriesPageState extends State<SubCategoriesPage> {
  late GoogleMapController mapController;

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

  Color redButtonTextColor = Color(0xFFEA4435);
  Color greenButtonTextColor = Color(0xff38A84F);
  Color yellowButtonTextColor = Color(0xff9B6E29);

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

  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();

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
        print(" ======================= snapshots is null");
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

  void showConfirmCheckOutDialog(
      String title, String content, String name, int index) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: cardColor,
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
                  deleteSubCategory(name, index);
                  Navigator.pop(context);
                },
                child: Text("Yes"),
              )
            ],
          );
        });
  }

  void showConfirmCheckOutDialogForDefault(String title, String content) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: cardColor,
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
                  deleteDefaultSubCategory();
                  Navigator.pop(context);
                },
                child: Text("Yes"),
              )
            ],
          );
        });
  }

  void deleteSubCategory(String name, int index) {
    listSurveyNames.forEach((mainCat) {
      myUserRef.child("$mainCat/$name").remove();
    });
    setState(() {
      listCategoryNames.removeAt(index);
    });
    mapCategoryNames.clear();
    listCategoryNames.asMap().forEach((key, value) {
      mapCategoryNames[key.toString()] = value;
    });
    categoryNamesRef.set(mapCategoryNames);
  }

  void deleteDefaultSubCategory() {
    listSurveyNames.forEach((mainCat) {
      myUserRef.child("$mainCat/random").remove();
    });
  }

  Future showCreateNewDialog(String title) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text(title),
            content: new Form(
              key: _formKey,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp("[a-zA-Z0-9 ]"),
                            allow: true)
                      ],
                      decoration: InputDecoration(hintText: "class1"),
                      controller: _textEditingController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter some text";
                        }
                        if (listCategoryNames.contains(value)) {
                          return "Category name already exists";
                        }
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        MaterialButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          color: startButtonColor,
                          onPressed: () {
                            if (onCreateCategoryPressed()) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            "Create",
                            style: TextStyle(color: greenButtonTextColor),
                          ),
                        ),
                        MaterialButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel"),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: <Widget>[],
          );
        });
  }

  bool onCreateCategoryPressed() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        listCategoryNames.add(_textEditingController.text.trim().toString());
      });
      mapCategoryNames["${listCategoryNames.length - 1}"] =
          listCategoryNames.last;
      categoryNamesRef.update(mapCategoryNames);

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
          title: Text("CLASS NAMES"),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'addclassname',
          onPressed: () {
            showCreateNewDialog("Add Class Name");
          },
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        body: listCategoryNames.isEmpty
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
                  return ListTile(
                    title: Text(listCategoryNames[i].toString()),
                    trailing: listCategoryNames[i].toString() != "random"
                        ? InkWell(
                            child: Icon(
                              Icons.delete,
                              color: redButtonTextColor,
                            ),
                            onTap: () {
                              showConfirmCheckOutDialog(
                                  "Are you sure to proceed?",
                                  "Deleting this will also result in deleting survey data associated with this sub category",
                                  listCategoryNames[i].toString(),
                                  i);
                            },
                          )
                        : InkWell(
                            child: Icon(
                              Icons.delete,
                              color: redButtonTextColor,
                            ),
                            onTap: () {
                              showConfirmCheckOutDialogForDefault(
                                  "Are you sure to proceed?",
                                  "Default category cannot be deleted but data associated to it will be deleted");
                            },
                          ),
                    leading: Text((i + 1).toString()),
                  );
                },
                itemCount: listCategoryNames.length,
              ));
  }
}
