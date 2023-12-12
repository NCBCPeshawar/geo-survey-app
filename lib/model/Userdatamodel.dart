class CategoryDataModel {
  List<PolygonDataModelMap> polygons = [];
  CategoryDataModel({required this.polygons});

  factory CategoryDataModel.setData(Map<dynamic, dynamic> jsonPolygons) {
    List<PolygonDataModelMap> listPolygons = [];

    jsonPolygons.forEach((k, v) {
      listPolygons.add(PolygonDataModelMap.setData(k, v));
    });
    return CategoryDataModel(polygons: listPolygons);
  }
}

class PolygonDataModelMap {
  String key;
  PolygonDataModel value;
  PolygonDataModelMap({required this.key, required this.value});

  factory PolygonDataModelMap.setData(String key, Map<dynamic, dynamic> value) {
    return PolygonDataModelMap(
        key: key, value: PolygonDataModel.fromJson(value));
  }
}

class PolygonDataModel {
  double area;
  String name;
  String timeStamp;
  List<String> vertex;
  PolygonDataModel(
      {required this.area,
      required this.name,
      required this.timeStamp,
      required this.vertex});

  factory PolygonDataModel.fromJson(Map<dynamic, dynamic> json) {
    return PolygonDataModel(
        area: double.parse(json["area"].toString()) ?? 0.0,
        name: json["name"] ?? "",
        timeStamp: json["timestamp"] ?? "",
        vertex: List<String>.from(json["vertex"] ?? {}));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonBody = {};
    jsonBody["name"] = this.name;
    jsonBody["area"] = this.area;
    jsonBody["timestamp"] = this.timeStamp;
    jsonBody["points"] = this.vertex;
    return jsonBody;
  }

  static List encodeToJson(List<PolygonDataModel> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toJson())).toList();
    return jsonList;
  }
}
