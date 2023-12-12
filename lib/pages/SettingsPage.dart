import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../MyUtils/AreaUnitUtils.dart';
import '../MyUtils/LengthUnitUtils.dart';
import '../MyUtils/SharedPrefUtils.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  Color startButtonColor = Color(0xFFE7F4EA);
  Color cancelButtonColor = Color(0xFFFCF8DD);
  Color stopButtonColor = Color(0xFFF9E6E4);
  Color disabledButtonColor = Colors.grey;

  Color greenButtonTextColor = Color(0xff38A84F);
  Color yellowButtonTextColor = Color(0xff9B6E29);
  Color redButtonTextColor = Color(0xFFEA4435);

  Color cardColor = Color(0xFFF4FBFA);

  late SharedPreferences prefs;

  final titleTextStyle = TextStyle().copyWith(
      fontSize: 19.0, color: Color(0xff262626), fontWeight: FontWeight.bold);

  late int areaUnitPref;
  late int lengthUnitPref;
  late List<int> selectionList;
  late List<String> areaUnitsList;
  late List<String> lengthUnitsList;

  SharedPrefUtils sharedPrefUtils = new SharedPrefUtils();

  void startProcesses() async {
    await sharedPrefUtils.init();
    areaUnitPref = await sharedPrefUtils.getAreaUnitPref();
    lengthUnitPref = await sharedPrefUtils.getLengthUnitPref();
    setState(() {
      areaUnitsList = AreaUnitUtils().getAreaUnitsList();
      lengthUnitsList = LengthUnitUtils().getLengthUnitsList();
    });
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
          title: Text("Settings"),
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Unit for Area",
                    style: titleTextStyle,
                  ),
                ),
                areaUnitsList == null
                    ? CircularProgressIndicator()
                    : ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: areaUnitsList.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            leading: Radio(
                              groupValue: areaUnitPref,
                              onChanged: (value) {
                                setState(() {
                                  areaUnitPref = value!;
                                });
                                sharedPrefUtils.setAreaUnitPref(value);
                              },
                              value: areaUnitsList.indexOf(areaUnitsList[i]),
                            ),
                            title: Text(areaUnitsList[i]),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(
                            height: 1.0,
                          );
                        },
                      ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Unit for Length",
                    style: titleTextStyle,
                  ),
                ),
                lengthUnitsList == null
                    ? CircularProgressIndicator()
                    : ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: lengthUnitsList.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            leading: Radio(
                              groupValue: lengthUnitPref,
                              onChanged: (value) {
                                setState(() {
                                  lengthUnitPref = value!;
                                });
                                sharedPrefUtils.setLengthUnitPref(value);
                              },
                              value:
                                  lengthUnitsList.indexOf(lengthUnitsList[i]),
                            ),
                            title: Text(lengthUnitsList[i]),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(
                            height: 1.0,
                          );
                        },
                      ),
              ],
            ),
          ),
        ));
  }
}
