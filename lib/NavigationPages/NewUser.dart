import 'package:android_intent/android_intent.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raghuvir_traders/Elements/AppDataBLoC.dart';
import 'package:raghuvir_traders/Elements/UserLogin.dart';
import 'package:raghuvir_traders/NavigationPages/CustomerHomePage..dart';
import 'package:raghuvir_traders/Services/UserLoginService.dart';

class NewUser extends StatefulWidget {
  static String id = "NewUser";
  @override
  _NewUserState createState() => _NewUserState();
}

class _NewUserState extends State<NewUser> {
  String _fName, _lName;
  bool _newUserLoad;
  String _address, _additionalAddress;
  @override
  void initState() {
    _address = "";
    _additionalAddress = "";
    _fName = "";
    _lName = "";
    _newUserLoad = false;
    super.initState();
  }

  Future _gpsService() async {
    if (!(await Geolocator().isLocationServiceEnabled())) {
      _checkGps();
      return null;
    } else
      return true;
  }

  Future _checkGps() async {
    if (!(await Geolocator().isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text("Can't get gurrent location"),
                content:
                    const Text('Please make sure you enable GPS and try again'),
                actions: <Widget>[
                  FlatButton(
                      child: Text('Ok'),
                      onPressed: () {
                        final AndroidIntent intent = AndroidIntent(
                            action:
                                'android.settings.LOCATION_SOURCE_SETTINGS');
                        intent.launch();
                        Navigator.of(context, rootNavigator: true).pop();
                        _gpsService();
                      })
                ],
              );
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkGps();
    final String phoneNumber = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Welcome",
                style: TextStyle(
                    color: AppDataBLoC.primaryColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Please Enter your Name to continue"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        _fName = value;
                      },
                      decoration: InputDecoration(
                        labelText: "First Name",
                      ),
                    ),
                  ),
                  Container(
                    width: 16.0,
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        _lName = value;
                      },
                      decoration: InputDecoration(
                        labelText: "Last Name",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: addressField(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  _additionalAddress = value;
                },
                decoration: InputDecoration(
                    labelText: "Flat No/House No/Additional details"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: newUserBtn(phoneNumber),
            ),
          ],
        ),
      ),
    );
  }

  Widget newUserBtn(String phoneNumber) {
    return Builder(
      builder: (context) => RaisedButton(
        onPressed: () async {
          FocusScope.of(context).unfocus();

          if (_fName == "" ||
              _lName == "" ||
              (_address + _additionalAddress) == "")
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text("Please fill all the fields"),
            ));
          else {
            setState(() {
              _newUserLoad = true;
            });
          }
        },
        color: AppDataBLoC.primaryColor,
        child: _newUserLoad == false
            ? Text(
                "Continue",
                style: TextStyle(color: AppDataBLoC.secondaryColor),
              )
            : FutureBuilder(
                future: UserLoginService.addUser(
                        phoneNumber,
                        _fName.trim() + " " + _lName.trim(),
                        _address + _additionalAddress)
                    .then((value) {
                  if (value.keys.toList()[0] == "User")
                    AppDataBLoC.data = value.values.toList()[0];
                  AppDataBLoC.setLastCart().then((value) {
                    UserLogin.setCachePhoneNumber(int.parse(phoneNumber));
                    Navigator.pushNamedAndRemoveUntil(
                        context, CustomerHomePage.id, (route) => false);
                  });
                  return value;
                }),
                builder: (context, snapshot) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppDataBLoC.primaryColor),
                  ),
                ),
              ),
      ),
    );
  }

  Widget addressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Center(
                child: _gpsLocation(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Icon(
                Icons.my_location,
                color: AppDataBLoC.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gpsLocation() {
    return FutureBuilder<Position>(
      future: Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<List<Placemark>>(
            future: Geolocator().placemarkFromPosition(snapshot.data),
            builder: (context, snapshot1) {
              if (snapshot1.hasData) {
                Placemark placeMark = snapshot1.data[0];
                String name = placeMark.name + ", ";
                String subLocality = placeMark.subLocality != ""
                    ? placeMark.subLocality + ", "
                    : "";
                String locality =
                    placeMark.locality != "" ? placeMark.locality + ", " : "";
                String administrativeArea = placeMark.administrativeArea != ""
                    ? placeMark.administrativeArea + ", "
                    : "";
                String postalCode = placeMark.postalCode + ", ";
                String country = placeMark.country;
                _address = name +
                    subLocality +
                    locality +
                    administrativeArea +
                    postalCode +
                    country;
                //print(_position);

                return Text(
                  _address,
                );
              } else {
                return Text("Detecting...");
              }
            },
          );
        } else {
          return Text("Detecting...");
        }
      },
    );
  }
}
