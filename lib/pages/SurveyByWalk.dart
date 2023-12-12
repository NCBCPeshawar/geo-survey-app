import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../MyUtils/AreaUnitUtils.dart';
import '../MyUtils/SharedPrefUtils.dart';
import '../model/Userdatamodel.dart';
import '../MyUtils/MapUtils.dart';

class SurveyByWalk extends StatefulWidget {
  User user;
  SurveyByWalk(this.user);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SurveyByWalkState();
  }
}

class _SurveyByWalkState extends State<SurveyByWalk> {
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  late Stream<Position> _streamPosition;
  late StreamSubscription<Position> _streamSubscription;
  var _geolocator = Geolocator();
  MapType _mapType = MapType.hybrid;

  SharedPrefUtils sharedPrefUtils = new SharedPrefUtils();
  late int areaUnitPref;

  final _formKeyForCreateSurvey = GlobalKey<FormState>();
  final _formKeyForCreateCategory = GlobalKey<FormState>();
  final _formKeyForFieldName = GlobalKey<FormState>();

  FirebaseDatabase database = FirebaseDatabase();
  late DatabaseReference myUserRef;
  late DatabaseReference usersRef;
  late DatabaseReference dataRef;
  late DatabaseReference surveyNamesRef;
  late DatabaseReference categoryNamesRef;

  final textEditingControllerSurvey = TextEditingController();
  final textEditingControllerCategory = TextEditingController();
  final textEditingControllerFieldName = TextEditingController();
  final textEditingControllerDescription = TextEditingController();

  Color startButtonColor = Color(0xFFE7F4EA);
  Color cancelButtonColor = Color(0xFFFCF8DD);
  Color stopButtonColor = Color(0xFFF9E6E4);
  Color disabledButtonColor = Colors.grey;

  Color greenButtonTextColor = Color(0xff38A84F);
  Color yellowButtonTextColor = Color(0xff9B6E29);
  Color redButtonTextColor = Color(0xFFEA4435);

  Color cardColor = Color(0xFFF4FBFA);

  Position? _currentPosition = null;
  bool _getting_location = false;
  static const timeout = const Duration(seconds: 40);
  static const ms = const Duration(milliseconds: 1);

  bool startButtonPressed = false;
  bool stopButtonPressed = false;
  bool cancelButtonPressed = false;

  bool startButtonEnabled = true;
  bool stopButtonEnabled = false;
  bool cancelButtonEnabled = false;

  List<LatLng> polygonPoints = [];
  List<List<LatLng>> polygonsPoints = [];

  int markerId = 0;
  int polygonId = 0;
  int markerNumber4Poly = 1;

  Set<Marker> _setMarkers = Set();
  Set<Polygon> _setPolygons = Set();
  int rotator = -1;

  List<DropdownMenuItem<String>> dropDownMenuItems = [];
  List<DropdownMenuItem<String>> catDropDownMenuItems = [];
  String selectedSurvey = "";
  String selectedCategory = "";
  Map<String, String> mapSurveyNames = Map<String, String>();
  Map<String, String> mapCategoryNames = Map<String, String>();
  List<String> listSurveyNames = [];
  List<String> listCategoryNames = [];

  String polyFieldName = "";
  double polyArea = 0.0;
  String documentId = "";
  bool showDataBox = false;

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

  var locationOptions = AndroidSettings(
    accuracy: LocationAccuracy.high,
    intervalDuration: const Duration(seconds: 7),
  );



  bool onCreateFieldNamePressed() {
    if (_formKeyForFieldName.currentState!.validate()) {
      myUserRef
          .child(selectedSurvey)
          .child(selectedCategory)
          .child("counter")
          .once()
          .then((DatabaseEvent snapshot) {
        if (snapshot.snapshot.value == null ||
            snapshot.snapshot.value as int < 20) {
          createPolygon();
          startButtonPressed = false;
          polygonId = polygonId + 1;
          polygonPoints.clear();
          _setMarkers.clear();
          setState(() {
            startButtonEnabled = true;
            stopButtonEnabled = false;
            cancelButtonEnabled = false;
          });
        } else {
          print('no more than 20 polygons');
          showMessageDialog("Limit Constraint",
              "$selectedCategory sub-category of $selectedSurvey main-category has reached maximum limit of 20 polygons.");
          startButtonPressed = false;
          polygonPoints.clear();
          _setMarkers.clear();
          setState(() {
            startButtonEnabled = true;
            stopButtonEnabled = false;
            cancelButtonEnabled = false;
          });
        }
      }).catchError((onError) => print("get counter error $onError"));

      return true;
    } else {
      return false;
    }
  }

  bool onCreateSurveyPressed() {
    if (_formKeyForCreateSurvey.currentState!.validate()) {
      listSurveyNames.add(textEditingControllerSurvey.text.toString());
      mapSurveyNames["${listSurveyNames.length - 1}"] = listSurveyNames.last;
      surveyNamesRef.update(mapSurveyNames);

      setState(() {
        dropDownMenuItems.add(DropdownMenuItem(
          value: textEditingControllerSurvey.text.toString(),
          child: Text(textEditingControllerSurvey.text.toString()),
        ));
        selectedSurvey = dropDownMenuItems[dropDownMenuItems.length - 1].value!;
      });
      return true;
    } else {
      return false;
    }
  }

  bool onCreateCategoryPressed() {
    if (_formKeyForCreateCategory.currentState!.validate()) {
      listCategoryNames.add(textEditingControllerCategory.text.toString());
      mapCategoryNames["${listCategoryNames.length - 1}"] =
          listCategoryNames.last;
      categoryNamesRef.update(mapCategoryNames);

      setState(() {
        catDropDownMenuItems.add(DropdownMenuItem(
          value: textEditingControllerCategory.text.toString(),
          child: Text(textEditingControllerCategory.text.toString()),
        ));
        selectedCategory =
            catDropDownMenuItems[catDropDownMenuItems.length - 1].value!;
      });
      return true;
    } else {
      return false;
    }
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

  Future showFieldNameDialog() async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text("Field/Area Name"),
            content: new Form(
              key: _formKeyForFieldName,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp("[a-zA-Z0-9 ]"),
                            allow: true)
                      ],
                      decoration: InputDecoration(hintText: "Name"),
                      controller: textEditingControllerFieldName,
                      validator: (value) {
                        if (value!.isEmpty) {
                          textEditingControllerFieldName.text = "unnamed";
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
                            if (onCreateFieldNamePressed()) {
                              _streamSubscription.cancel();
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            "Save",
                            style: TextStyle(color: greenButtonTextColor),
                          ),
                        ),
                        MaterialButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              startButtonPressed = true;
                            });
                          },
                          color: cancelButtonColor,
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: yellowButtonTextColor),
                          ),
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

  Future showCreateNewSurveyDialog(String title) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text(title),
            content: new Form(
              key: _formKeyForCreateSurvey,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp("[a-zA-Z0-9 ]"),
                            allow: true)
                      ],
                      decoration: InputDecoration(hintText: "survey1"),
                      controller: textEditingControllerSurvey,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter some text";
                        }
                        if (listSurveyNames.contains(value)) {
                          return "Survey name already exists";
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
                            if (onCreateSurveyPressed()) {
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
                          color: cancelButtonColor,
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: yellowButtonTextColor),
                          ),
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

  Future showCreateNewCategoryDialog(String title) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text(title),
            content: new Form(
              key: _formKeyForCreateCategory,
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
                      controller: textEditingControllerCategory,
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
                          color: cancelButtonColor,
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: yellowButtonTextColor),
                          ),
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


  Future getMyPositionStream() async {
    final GoogleMapController controller = await mapController.future;
    _streamPosition =
        Geolocator.getPositionStream(locationSettings: locationOptions);

    _streamSubscription = _streamPosition.listen((Position position) async {
      setState(() {
        _currentPosition = position;
        if (startButtonPressed == true) {
          addMarkerOnMap(LatLng(position.latitude, position.longitude));
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 18.0),
          ));
        }
      });

      _getting_location = true;
    });
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

  Future<void> addMarkerOnMap(LatLng latLng) async {
    BitmapDescriptor bitmapDescriptor =
        await MapUtils().createCustomMarkerBitmap(markerNumber4Poly);
    setState(() {
      _setMarkers.add(Marker(
          markerId: MarkerId(markerId.toString()),
          position: latLng,
          icon: bitmapDescriptor));
    });
    markerNumber4Poly++;
    markerId = markerId + 1;
    polygonPoints.add(latLng);
  }

  void createPolygon() {
    polygonsPoints.add(List.of(polygonPoints));
    Map<String, dynamic> mapPolygon = Map<String, dynamic>();
    polygonPoints.asMap().forEach((i, l) {
      mapPolygon["${i.toString()}"] =
          l.latitude.toString() + "," + l.longitude.toString();
    });

    var currentCatRef = myUserRef.child(selectedSurvey).child(selectedCategory);
    String nextKey = currentCatRef.child("polygons").push().key!;

    currentCatRef.update(<String, dynamic>{"color": "FF0000"});
    currentCatRef.child("polygons").child(nextKey).set(<String, dynamic>{
      "vertex": mapPolygon,
      "timestamp": DateTime.now().toUtc().toString(),
      "name": textEditingControllerFieldName.text.trim().toString()
    }).then((value) {
      print('--- added in---');
      setState(() {
        _setPolygons.add(new Polygon(
          consumeTapEvents: true,
          onTap: () {
            print('tapped');
            currentCatRef
                .child('polygons')
                .child(nextKey)
                .get()
                .then((DataSnapshot snapshot) {
              var polyData = snapshot.value as Map;
              setState(() {
                showDataBox = true;
                documentId = nextKey;
                polyFieldName =
                    textEditingControllerFieldName.text.trim().toString();
                polyArea = polyData['area'] ?? 0;
              });
            });
          },
          polygonId: PolygonId(nextKey),
          points: List.of(polygonsPoints[polygonsPoints.length - 1]),
          fillColor: Color.fromARGB(125, 255, 0, 0),
          strokeWidth: 2,
          strokeColor: Colors.red,
        ));
      });
    }).catchError((onError) {
      print('---added error--- ${onError.toString()}');
    });
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
    await sharedPrefUtils.init();
    areaUnitPref = await sharedPrefUtils.getAreaUnitPref();
    setFirebaseSettings();
    getFirebaseData();
  }

  void onPopupMenuSelected(String selected) {
    switch (selected) {
      case "create_new_survey":
        {
          showCreateNewSurveyDialog("Add Survey Name");
        }
        break;
      case "create_new_category":
        {
          showCreateNewCategoryDialog("Add Class Name");
        }
        break;
      default:
    }
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

  void toPolygon({bool next = false, bool previous = false}) {
    setState(() {
      showDataBox = false;
    });
    if (!next && !previous) {
      return;
    }
    if (next) {
      if (rotator < _setPolygons.length - 1 && rotator >= -1) {
        setState(() {
          rotator = rotator + 1;
        });
        moveCamerato(
            calculateCenteroid(_setPolygons.elementAt(rotator).points));
      } else {
        setState(() {
          rotator = _setPolygons.length - 1;
        });
        moveCamerato(
            calculateCenteroid(_setPolygons.elementAt(rotator).points));
        print('rotator out of range next >>>>>>>>>>>>');
      }
    } else if (previous) {
      if (rotator < _setPolygons.length && rotator >= 1) {
        setState(() {
          rotator = rotator - 1;
        });
        moveCamerato(
            calculateCenteroid(_setPolygons.elementAt(rotator).points));
      } else {
        setState(() {
          rotator = 0;
        });
        moveCamerato(
            calculateCenteroid(_setPolygons.elementAt(rotator).points));
        print('rotator out of range prev <<<<<<<<<<<<<<');
      }
    } else {
      return;
    }
  }

  Future<void> moveCamerato(LatLng centeroid) async {
    final GoogleMapController controller = await mapController.future;
    setState(() {
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: centeroid, zoom: 17.0),
      ));
    });
  }

  void onViewPolygonsClick({bool export = false}) {
    CategoryDataModel categoryDataModel;
    print("$selectedSurvey > $selectedCategory");
    myUserRef
        .child("$selectedSurvey/$selectedCategory/polygons")
        .once()
        .then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value == null) {
        // polygons does not exist of this category, means that category also doesnot exist
        showMessageDialog("Not Found", "Polygons not found for this category");

        return;
      }
      Map<dynamic, dynamic> map = snapshot.snapshot.value as Map;
      categoryDataModel = CategoryDataModel.setData(map);

      createPolygons(categoryDataModel.polygons);
    });
  }

  Future<void> createPolygons(List<PolygonDataModelMap> polygons) async {
    _setPolygons.clear();
    polygonId = 0;
    List<LatLng> listLatLng = [];
    polygons.forEach((p) {
      // skip corrupted polygons
      if (p.value.vertex.isNotEmpty) {
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
                  polyFieldName = p.value.name;
                  polyArea = p.value.area;
                });
              }));
        });
        polygonId = polygonId + 1;
      }
    });
    // if no good polygon
    if (polygonId == 0) {
      showMessageDialog("Not Found", "Polygons not found for this category");
    } else {
     
    }
  }

  LatLng calculateCenteroid(List<LatLng> points) {
    print("points >>>" + points.toString());
    Map<String, double> centeroid = {"lat": 0.0, "lng": 0.0};
    List<double> lat = [];
    List<double> lng = [];

    points.forEach((point) {
      lat.add(point.latitude);
      lng.add(point.longitude);
    });

    double x1 = lat.reduce(min);
    double y1 = lng.reduce(min);
    double x2 = lat.reduce(max);
    double y2 = lng.reduce(max);

    centeroid["lat"] = x1 + ((x2 - x1) / 2);
    centeroid["lng"] = y1 + ((y2 - y1) / 2);

    return LatLng(centeroid["lat"]!, centeroid["lng"]!);
  }

  Future<void> getLastKnownPosition() async {
    bool locationStatus = await checkLocationStatus();
    if (locationStatus) {
      final GoogleMapController controller = await mapController.future;
      Geolocator.getCurrentPosition().then((position) {
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0),
        ));
      });
    } else {
      showMessageDialog('Location Permission',
          'Kindly turn on and grant location permission in order to get position');
    }
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
    textEditingControllerSurvey.dispose();
    textEditingControllerCategory.dispose();
    textEditingControllerFieldName.dispose();
    textEditingControllerDescription.dispose();
    _streamSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text("SURVEY BY WALK"),
          actions: <Widget>[
            PopupMenuButton(
              onSelected: (s) => onPopupMenuSelected(s),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: "create_new_survey",
                    child: Text("Add Survey Name"),
                  ),
                  PopupMenuItem(
                    value: "create_new_category",
                    child: Text("Add Class Name"),
                  )
                ];
              },
            )
          ],
        ),
        body: Stack(
          children: <Widget>[
            Container(
              child: GoogleMap(
                mapType: _mapType,
                onMapCreated: (GoogleMapController controller) {
                  mapController.complete(controller);
                },
                markers: _setMarkers,
                polygons: _setPolygons,
                initialCameraPosition: CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 0,
                ),
                myLocationEnabled: true,
                compassEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
            showDataBox == true
                ? Container(
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.all(Radius.circular(6))),
                    margin: EdgeInsets.fromLTRB(8.0, 50.0, 8.0, 8.0),
                    child: Container(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text("Name: $polyFieldName"),
                          Text(
                              "Area: ${AreaUnitUtils().getAreaAsString(polyArea, areaUnitPref)}"),
                          InkWell(
                            child: Icon(
                              Icons.delete,
                              color: redButtonTextColor,
                            ),
                            onTap: () {
                              print("delete document with Id = $documentId");
                              myUserRef
                                  .child(
                                      "$selectedSurvey/$selectedCategory/polygons/$documentId")
                                  .remove()
                                  .then((onValue) {
                                setState(() {
                                  _setPolygons.removeWhere((polygon) {
                                    return polygon.polygonId.value ==
                                        documentId;
                                  });
                                  showDataBox = false;
                                });
                                print("deleted....");
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
            Container(
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Color.fromARGB(71, 102, 155, 188),
                        blurRadius: 10,
                        offset: Offset(0, 0),
                        spreadRadius: 5)
                  ],
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(18),
                      topRight: Radius.circular(18)),
                  color: Theme.of(context).primaryColorLight),
              width: 200.0,
              margin: EdgeInsets.only(top: 120.0),
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Text(_setPolygons.length.toString() + " items"),
                  _setPolygons.isEmpty
                      ? Text("")
                      : Expanded(
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(18),
                                      topLeft: Radius.circular(18)),
                                  color: Theme.of(context).primaryColorLight,
                                ),
                                width: 40,
                                child: InkWell(
                                  onTap: () => toPolygon(previous: true),
                                  child: Icon(
                                    Icons.chevron_left,
                                  ),
                                )),
                            Text("${rotator + 1}"),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(18),
                                    topRight: Radius.circular(18)),
                                color: Theme.of(context).primaryColorLight,
                              ),
                              width: 40,
                              child: InkWell(
                                onTap: () => toPolygon(next: true),
                                child: Icon(
                                  Icons.chevron_right,
                                ),
                              ),
                            ),
                          ],
                        ))
                ],
              ),
            ),
            listSurveyNames.length > 0 && listCategoryNames.length > 0
                ? Container(
                    padding: EdgeInsets.only(top: 0.0),
                    child: Column(children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          startButtonWidget(context),
                          stopButtonWidget(context),
                          cancelButtonWidget(context),
                        ],
                      ),
                    ]),
                  )
                : Container(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 5, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'layersbtnwalkpolygon',
                      onPressed: () {
                        setState(() {
                          _mapType = MapUtils().switchMapType(_mapType);
                        });
                      },
                      child: Icon(
                        Icons.layers,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    FloatingActionButton(
                      heroTag: 'locationbtnwalkpolygon',
                      onPressed: () {
                        getLastKnownPosition();
                      },
                      child: Icon(
                        Icons.my_location,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),
            listSurveyNames.length > 0 && listCategoryNames.length > 0
                ? Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          boxShadow: [
                            BoxShadow(
                                color: Color.fromARGB(71, 102, 155, 188),
                                blurRadius: 20,
                                offset: Offset(0, -6),
                                spreadRadius: 1)
                          ]),
                      margin: EdgeInsets.fromLTRB(5.0, 0, 0, 5.0),
                      width: MediaQuery.of(context).size.width - 80,
                      height: 210.0,
                      padding: EdgeInsets.fromLTRB(10.0, 10, 10, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Survey Name:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                                  print("$selectedSurvey > $selectedCategory");
                                });
                              },
                            ),
                          ),
                          Text(
                            "Class Name:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                                  print("$selectedSurvey > $selectedCategory");
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      rotator = -1;
                                      showDataBox = false;
                                      _setPolygons.clear();
                                    });
                                    onViewPolygonsClick();
                                  },
                                  child: Text("Show Polygons")),
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      rotator = -1;
                                      showDataBox = false;
                                      _setPolygons.clear();
                                    });
                                  },
                                  child: Text("Clear Polygons"))
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
          ],
        ));
  }

  Widget startButtonWidget(BuildContext context) {
    return SizedBox(
      //width: 150.0,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        color:
            startButtonEnabled == true ? startButtonColor : disabledButtonColor,
        onPressed: () async {
          bool locationStatus = await checkLocationStatus();
          if (locationStatus) {
            getMyPositionStream();
            startButtonEnabled == true
                ? () {
                    markerNumber4Poly = 1;
                    setState(() {
                      startButtonPressed = true;
                      stopButtonEnabled = true;
                      cancelButtonEnabled = true;
                      startButtonEnabled = false;
                    });
                  }()
                : print("start button disabled");
          } else {
            showMessageDialog('Location Permission',
                'Kindly turn on and grant location permission in order to get position');
          }
        },
        child: Text("Start", style: TextStyle(color: greenButtonTextColor)),
      ),
    );
  }

  Widget stopButtonWidget(BuildContext context) {
    return SizedBox(
      //width: 150.0,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        color:
            stopButtonEnabled == true ? stopButtonColor : disabledButtonColor,
        onPressed: () {
          stopButtonEnabled == true
              ? () async {
                  if (polygonPoints.length > 2) {
                    setState(() {
                      startButtonPressed = false;
                    });
                    await showFieldNameDialog();
                  } else {
                    print("atleast 3 points are required");
                  }
                }()
              : print("stop is disabled");
        },
        child: Text(
          "Stop",
          style: TextStyle(color: redButtonTextColor),
        ),
      ),
    );
  }

  Widget cancelButtonWidget(BuildContext context) {
    return SizedBox(
      //width: 150.0,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        color: cancelButtonEnabled == true
            ? cancelButtonColor
            : disabledButtonColor,
        onPressed: () {
          _streamSubscription.cancel();
          cancelButtonEnabled == true
              ? () {
                  startButtonPressed = false;
                  setState(() {
                    _setMarkers.clear();
                    polygonPoints.clear();
                    startButtonEnabled = true;
                    stopButtonEnabled = false;
                    cancelButtonEnabled = false;
                  });
                }()
              : print("cancel button disabled");
        },
        child: Text(
          "Cancel",
          style: TextStyle(color: yellowButtonTextColor),
        ),
      ),
    );
  }
}
