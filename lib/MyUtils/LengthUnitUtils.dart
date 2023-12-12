class LengthUnitUtils {
  List<String> _lengthUnitsList = [
    "m",
    "km",
    "ft",
    "yd",
  ];

  List<String> getLengthUnitsList() {
    return _lengthUnitsList;
  }

  double getLengthConvertedFromM(double value, int unit) {
    switch (unit) {
      // m
      case 0:
        return value;
        break;
      // km
      case 1:
        return value * 0.001;
        break;
      // ft
      case 2:
        return value * 3.281;
      // yd
      case 3:
        return value * 1.094;
      default:
        return value;
    }
  }

  String getLengthAsString(double length, int unitIndex) {
    return double.parse(getLengthConvertedFromM(length, unitIndex).toString())
            .toStringAsFixed(3) +
        " " +
        _lengthUnitsList[unitIndex];
  }
}
