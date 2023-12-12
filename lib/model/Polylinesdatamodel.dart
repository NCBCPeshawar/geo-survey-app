class PolylinesDataModel {
  List<PolylineDataModelMap> polylines = [];
  PolylinesDataModel({required this.polylines});

  factory PolylinesDataModel.setData(Map<dynamic, dynamic> jsonPolygons) {
    List<PolylineDataModelMap> listPolygons = [];

    jsonPolygons.forEach((k, v) {
      listPolygons.add(PolylineDataModelMap.setData(k, v));
    });
    return PolylinesDataModel(polylines: listPolygons);
  }
}

class PolylineDataModelMap {
  String key;
  PolylineDataModel value;
  PolylineDataModelMap({required this.key, required this.value});

  factory PolylineDataModelMap.setData(
      String key, Map<dynamic, dynamic> value) {
    return PolylineDataModelMap(
        key: key, value: PolylineDataModel.fromJson(value));
  }
}

class PolylineDataModel {
  String name;
  String timeStamp;
  List<String> vertex;
  String distance;
  PolylineDataModel(
      {required this.name,
      required this.timeStamp,
      required this.vertex,
      required this.distance});

  factory PolylineDataModel.fromJson(Map<dynamic, dynamic> json) {
    return PolylineDataModel(
        name: json["name"],
        distance: json["distance"],
        timeStamp: json["timestamp"],
        vertex: List<String>.from(json["vertex"]));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonBody = {};
    jsonBody["name"] = this.name;
    jsonBody["distance"] = this.distance;
    jsonBody["timestamp"] = this.timeStamp;
    jsonBody["points"] = this.vertex;
    return jsonBody;
  }

  static List encodeToJson(List<PolylineDataModel> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toJson())).toList();
    return jsonList;
  }
}
