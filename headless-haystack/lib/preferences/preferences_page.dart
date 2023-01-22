import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/location/location_model.dart';
import 'package:openhaystack_mobile/preferences/user_preferences_model.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class PreferencesPage extends StatefulWidget {
  /// Displays this preferences page with information about the app.
  const PreferencesPage({Key? key}) : super(key: key);

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            getLocationTile(),
            getUrlTile(),
            ListTile(
              title: getAbout(),
            ),
          ],
        ),
      ),
    );
  }

  getLocationTile() {
    return SwitchSettingsTile(
      settingKey: locationPreferenceKnownKey,
      title: 'Show this devices location',
      onChange: (showLocation) {
        var locationModel = Provider.of<LocationModel>(context, listen: false);
        if (showLocation) {
          locationModel.requestLocationUpdates();
        } else {
          locationModel.cancelLocationUpdates();
        }
      },
    );
  }

  getUrlTile() {
    return TextInputSettingsTile(
      initialValue: 'http://localhost:56176',
      settingKey: haystackurl,
      title: 'Url to Headless Haystack server',
      validator: (String? url) {
        if (url != null &&
            url.startsWith(RegExp('http[s]?://', caseSensitive: false))) {
          return null;
        }
        return "Invalid Url";
      },
    );
  }

  getAbout() {
    return TextButton(
        style: ButtonStyle(
            padding:
                MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(10)),
            foregroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                return Colors.white;
              },
            ),
            backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                return Colors.indigo;
              },
            )),
        child: const Text('About'),
        onPressed: () => showAboutDialog(
              context: context,
            ));
  }
}
