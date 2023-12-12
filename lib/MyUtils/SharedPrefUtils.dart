import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefUtils {
  late SharedPreferences _prefs;
  late int _areaUnitPref;
  late int _lengthUnitPref;
  
  SharedPrefUtils();

  Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<int> getAreaUnitPref() async {
    _areaUnitPref = _prefs.getInt("areaUnitPref") ?? 0;
    return _areaUnitPref;
  }

  Future<void> setAreaUnitPref(value) async {
    await _prefs.setInt("areaUnitPref", value);
  }

  Future<int> getLengthUnitPref() async {
    _lengthUnitPref = _prefs.getInt("lengthUnitPref") ?? 0;
    return _lengthUnitPref;
  }

  Future<void> setLengthUnitPref(value) async {
    await _prefs.setInt("lengthUnitPref", value);
  }
}
