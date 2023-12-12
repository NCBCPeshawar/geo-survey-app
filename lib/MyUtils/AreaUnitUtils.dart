// enum areaUnits { m2, hec, km2, ft2, yd2, ac, kanal }

class AreaUnitUtils {
  List<String> _areaUnitsList = [
    "m²",
    "ha",
    "km²",
    "ft²",
    "yd²",
    "ac",
    "kanal"
  ];

  List<String> getAreaUnitsList() {
    return _areaUnitsList;
  }

  double getAreaConvertedFromM2(double value, int unit) {
    switch (unit) {
      // m
      case 0:
        return value;
        break;
      // ha
      case 1:
        return value * 0.0001;
        break;
      // km2
      case 2:
        return value * 0.000001;
      // ft2
      case 3:
        return value * 10.764;
      // yd2
      case 4:
        return value * 1.196;
      // ac
      case 5:
        return value / 4047;
      // kanal
      case 6:
        return value / 506;
      default:
        return value;
    }
  }

  String getAreaAsString(double area, int unitIndex) {
    return double.parse(getAreaConvertedFromM2(area, unitIndex).toString())
            .toStringAsFixed(3) +
        " " +
        _areaUnitsList[unitIndex];
  }
}
