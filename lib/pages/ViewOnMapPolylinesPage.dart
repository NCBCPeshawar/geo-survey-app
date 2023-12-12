import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../MyUtils/LengthUnitUtils.dart';
import '../model/Polylinesdatamodel.dart';
import '../MyUtils/MapUtils.dart';
import '../MyUtils/SharedPrefUtils.dart';
import 'dart:math';

class ViewOnMapPolylinesPage extends StatefulWidget {
  User user;
  ViewOnMapPolylinesPage(this.user);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ViewOnMapPolylinesPageState();
  }
}

class _ViewOnMapPolylinesPageState extends State<ViewOnMapPolylinesPage> {
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  MapType _mapType = MapType.hybrid;
  SharedPrefUtils sharedPrefUtils = new SharedPrefUtils();
  late int lengthUnitPref;

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

  Set<Polyline> _setPolygons = Set();
  int rotator = -1;

  List<DropdownMenuItem<String>> dropDownMenuItems = [];
  List<DropdownMenuItem<String>> catDropDownMenuItems = [];
  String selectedSurvey = "";
  String selectedCategory = "";

  String fieldName = "";
  double totalDistance = 0.0;
  String documentId = "";

  Map<String, String> mapSurveyNames = Map<String, String>();
  Map<String, String> mapCategoryNames = Map<String, String>();
  List<String> listSurveyNames = [];
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
      if (snapshot.snapshot == null) {
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
    intervalDuration: Duration(seconds: 5),
  );


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
    PolylinesDataModel categoryDataModel;
    print("$selectedSurvey > $selectedCategory");
    myUserRef
        .child("$selectedSurvey/$selectedCategory/polylines")
        .once()
        .then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value == null) {
        // polygons does not exist of this category, means that category also doesnot exist
        showMessageDialog("Not Found", "Polylines not found for this category");
        setState(() {
          _setPolygons.clear();
          showDataBox = false;
        });
        return;
      }
      Map<dynamic, dynamic> map = snapshot.snapshot.value as Map;

      categoryDataModel = PolylinesDataModel.setData(map);

      createPolygons(categoryDataModel.polylines);

      if (export) writeToFile(categoryDataModel.polylines);
    });
  }

  Future<void> createPolygons(List<PolylineDataModelMap> polygons) async {
    _setPolygons.clear();
    List<LatLng> listLatLng = [];
    polygons.forEach((p) {
      setState(() {
        _setPolygons.add(new Polyline(
            polylineId: PolylineId(p.key),
            points: p.value.vertex.map((v) {
              List<String> latlng = v.split(",");
              // create list of markers of this polygon and add to main list of latlng
              listLatLng.add(
                  LatLng(double.parse(latlng[0]), double.parse(latlng[1])));
              return LatLng(double.parse(latlng[0]), double.parse(latlng[1]));
            }).toList(),
            color: Colors.red,
            width: 4,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                showDataBox = true;
                documentId = p.key;
                fieldName = p.value.name;
                totalDistance = double.parse(p.value.distance);
              });
            }));
      });

      polygonId = polygonId + 1;
    });
    LatLng centeroid = calculateCenteroid(listLatLng);
    final GoogleMapController controller = await mapController.future;
    setState(() {
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: centeroid, zoom: 15.0),
      ));
    });
  }

  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();

    return directory!.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$selectedSurvey-$selectedCategory-polylines.json');
  }

  Future<void> writeToFile(List<PolylineDataModelMap> data) async {
    List<PolylineDataModel> pdm = [];
    final file = await _localFile;

    data.forEach((p) {
      pdm.add(PolylineDataModel(
          distance: p.value.distance,
          name: p.value.name,
          timeStamp: p.value.timeStamp,
          vertex: p.value.vertex.map((v) {
            return v.toString();
          }).toList()));
    });

    List jsonList = PolylineDataModel.encodeToJson(pdm);
    print('saving data');
    await file.writeAsString(jsonEncode(jsonList));
    print('data saved');
    Share.file(
        "$selectedSurvey-$selectedCategory-polylines",
        "$selectedSurvey-$selectedCategory-polylines.json",
        await file.readAsBytes(),
        "application/json");
  }

  LatLng calculateCenteroid(List<LatLng> points) {
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
    lengthUnitPref = await sharedPrefUtils.getLengthUnitPref();
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
          title: Text("DATA ON MAP"),
        ),
        body: Stack(
          children: <Widget>[
            Container(
              child: GoogleMap(
                mapType: _mapType,
                onMapCreated: (GoogleMapController controller) =>
                    mapController.complete(controller),
                polylines: _setPolygons,
                initialCameraPosition: CameraPosition(
                  target: LatLng(0.0, 0.0),
                  zoom: 0.0,
                ),
                myLocationEnabled: true,
                compassEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
            showDataBox == true
                ? Card(
                    child: Container(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text("Name: $fieldName"),
                          Text("Length: " +
                              LengthUnitUtils().getLengthAsString(
                                  totalDistance, lengthUnitPref)),
                          InkWell(
                            child: Icon(
                              Icons.delete,
                              color: redButtonTextColor,
                            ),
                            onTap: () {
                              print("delete document with Id = $documentId");
                              myUserRef
                                  .child(
                                      "$selectedSurvey/$selectedCategory/polylines/$documentId")
                                  .remove()
                                  .then((onValue) {
                                setState(() {
                                  _setPolygons.removeWhere((polygon) {
                                    return polygon.polylineId.value ==
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
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 10, 224),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'layersbtnviewpolyline',
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
                  ],
                ),
              ),
            ),
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
                                  print("$selectedSurvey > $selectedCategory");
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
                                  print("$selectedSurvey > $selectedCategory");
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              MaterialButton(
                                child: Text(
                                  "View Data",
                                  style: TextStyle(color: greenButtonTextColor),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                color: startButtonColor,
                                onPressed: () {
                                  setState(() {
                                    rotator = -1;
                                    showDataBox = false;
                                    _setPolygons.clear();
                                  });
                                  onViewPolygonsClick();
                                },
                              ),
                              MaterialButton(
                                child: Text(
                                  "Export Data",
                                  style: TextStyle(color: greenButtonTextColor),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                color: startButtonColor,
                                onPressed: () {
                                  setState(() {
                                    showDataBox = false;
                                    _setPolygons.clear();
                                    rotator = -1;
                                  });
                                  onViewPolygonsClick(export: true);
                                },
                              )
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
}
