import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as flutter_custom_tabs;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }
  runApp(const MyApp());
}

enum LaunchType {
  urlInAppWebView,
  urlExternalApplication,
  urlCustomTabs,
  dialer,
  sms,
  email,
  mapSearchQuery,
  mapSearchCoordinate,
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String _link = 'https://flutter.dev/';
  final String _call = '+1 (123) 456-7890';
  final String _email = 'johndoe@example.com';
  final double _lat = 37.4220041;
  final double _long = -122.0862462;
  final String _query = '1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA';
  final List<Marker> _markers = <Marker>[];
  final Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId('SomeId'),
        position: LatLng(_lat, _long),
        infoWindow: InfoWindow(
          title: 'ABC Company',
          snippet: 'XYZ Location',
          onTap: _checkAndOpenMapsWithQuery,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Launcher Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _checkAndOpenURLInAppWebView,
                  child: const Text('Check & open URL in in-app web view'),
                ),
                ElevatedButton(
                  onPressed: _checkAndOpenURLExternalApplication,
                  child: const Text('Check & open URL in external app'),
                ),
                ElevatedButton(
                  onPressed: _checkAndOpenURLInCustomTab,
                  child: const Text('Check & open URL in custom tabs'),
                ),
                ElevatedButton(
                  onPressed: _checkAndOpenDialer,
                  child: const Text('Check & open Phone dialer app'),
                ),
                ElevatedButton(
                  onPressed: _checkAndOpenEmail,
                  child: const Text('Check & open Phone Email app'),
                ),
                ElevatedButton(
                  onPressed: _checkAndOpenDialerMessageApp,
                  child: const Text('Check & open Phone SMS app'),
                ),
                ElevatedButton(
                  onPressed: _checkAndOpenMapsWithQuery,
                  child: const Text('Check & open Map (using search query)'),
                ),
                ElevatedButton(
                  onPressed: _checkAndOpenMapsWithCoordinates,
                  child: const Text('Check & open Map (using map co-ordinate)'),
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: GoogleMap(
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_lat, _long),
                        zoom: 10,
                      ),
                      zoomControlsEnabled: false,
                      markers: Set<Marker>.of(_markers),
                      onMapCreated: (GoogleMapController c) async {
                        await c.showMarkerInfoWindow(_markers.first.markerId);
                        _controller.complete(c);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _launchURLForCustomTab({
    required Uri uri,
  }) async {
    final theme = Theme.of(context);
    try {
      await flutter_custom_tabs.launch(
        uri.toString(),
        customTabsOption: flutter_custom_tabs.CustomTabsOption(
          toolbarColor: theme.primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: false,
          showPageTitle: true,
          animation: flutter_custom_tabs.CustomTabsSystemAnimation.slideIn(),
          extraCustomTabs: const <String>[],
          enableInstantApps: false,
          headers: const {},
        ),
        safariVCOption: flutter_custom_tabs.SafariViewControllerOption(
          preferredBarTintColor: theme.primaryColor,
          preferredControlTintColor: Colors.black,
          barCollapsingEnabled: true,
          entersReaderIfAvailable: false,
          statusBarBrightness:
          SchedulerBinding.instance.window.platformBrightness,
          dismissButtonStyle:
              flutter_custom_tabs.SafariViewControllerDismissButtonStyle.close,
        ),
      );
      return Future.value(true);
    } catch (e) {
      debugPrint(e.toString());
      return Future.value(false);
    }
  }

  Future<void> _checkAndOpenURLInCustomTab() async {
    final Uri link = Uri.parse(_link);
    final bool open = await canLaunchUrl(link);
    if (open) {
      final bool working = await _launchURLForCustomTab(
        uri: link,
      );
      if (working) {
      } else {
        errorHandlerForLaunch(LaunchType.urlCustomTabs);
      }
    } else {
      errorHandlerForOpen(LaunchType.urlCustomTabs);
    }
    return Future.value();
  }

  Future<void> _checkAndOpenURLInAppWebView() async {
    final Uri link = Uri.parse(_link);
    final bool open = await canLaunchUrl(link);
    if (open) {
      final bool working = await launchUrl(
        link,
        mode: LaunchMode.inAppWebView,
      );
      if (working) {
      } else {
        errorHandlerForLaunch(LaunchType.urlInAppWebView);
      }
    } else {
      errorHandlerForOpen(LaunchType.urlInAppWebView);
    }
    return Future.value();
  }

  Future<void> _checkAndOpenURLExternalApplication() async {
    final Uri link = Uri.parse(_link);
    final bool open = await canLaunchUrl(link);
    if (open) {
      final bool working = await launchUrl(
        link,
        mode: LaunchMode.externalApplication,
      );
      if (working) {
      } else {
        errorHandlerForLaunch(LaunchType.urlExternalApplication);
      }
    } else {
      errorHandlerForOpen(LaunchType.urlExternalApplication);
    }
    return Future.value();
  }

  Future<void> _checkAndOpenDialer() async {
    final Uri link = Uri(scheme: 'tel', path: _call);
    final bool open = await canLaunchUrl(link);
    if (open) {
      final bool working = await launchUrl(link);
      if (working) {
      } else {
        errorHandlerForLaunch(LaunchType.dialer);
      }
    } else {
      errorHandlerForOpen(LaunchType.dialer);
    }
    return Future.value();
  }

  Future<void> _checkAndOpenEmail() async {
    final link = Uri(
      scheme: 'mailto',
      path: _email,
      query: encodeQueryParameters(
        <String, String>{
          'subject': '',
        },
      ),
    );

    final bool open = await canLaunchUrl(link);
    if (open) {
      final bool working = await launchUrl(link);
      if (working) {
      } else {
        errorHandlerForLaunch(LaunchType.email);
      }
    } else {
      errorHandlerForOpen(LaunchType.email);
    }
    return Future.value();
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries.map((MapEntry<String, String> e) {
      return '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}';
    }).join('&');
  }

  Future<void> _checkAndOpenDialerMessageApp() async {
    final Uri link = Uri(
      scheme: 'sms',
      path: _call,
      queryParameters: <String, String>{
        'body': Uri.encodeComponent(
          '',
        ),
      },
    );

    final bool open = await canLaunchUrl(link);
    if (open) {
      final bool working = await launchUrl(link);
      if (working) {
      } else {
        errorHandlerForLaunch(LaunchType.sms);
      }
    } else {
      errorHandlerForOpen(LaunchType.sms);
    }
    return Future.value();
  }

  Future<void> _checkAndOpenMapsWithQuery() async {
    final bool working = await launchUrl(
      createQueryUrl(_query),
      mode: LaunchMode.externalApplication,
    );
    if (working) {
    } else {
      errorHandlerForLaunch(LaunchType.mapSearchQuery);
    }
    return Future.value();
  }

  Future<void> _checkAndOpenMapsWithCoordinates() async {
    final bool working = await launchUrl(
      createCoordinatesUrl(_lat, _long, _query),
      mode: LaunchMode.externalApplication,
    );
    if (working) {
    } else {
      errorHandlerForLaunch(LaunchType.mapSearchCoordinate);
    }
    return Future.value();
  }

  Uri createQueryUrl(String query) {
    Uri uri;

    if (kIsWeb) {
      uri = Uri.https(
          'www.google.com', '/maps/search/', {'api': '1', 'query': query});
    } else if (Platform.isAndroid) {
      uri = Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': query});
    } else if (Platform.isIOS) {
      uri = Uri.https('maps.apple.com', '/', {'q': query});
    } else {
      uri = Uri.https(
          'www.google.com', '/maps/search/', {'api': '1', 'query': query});
    }

    return uri;
  }

  Uri createCoordinatesUrl(double latitude, double longitude, [String? label]) {
    Uri uri;

    if (kIsWeb) {
      uri = Uri.https('www.google.com', '/maps/search/',
          {'api': '1', 'query': '$latitude,$longitude'});
    } else if (Platform.isAndroid) {
      var query = '$latitude,$longitude';

      if (label != null) query += '($label)';

      uri = Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': query});
    } else if (Platform.isIOS) {
      var params = {'ll': '$latitude,$longitude'};

      if (label != null) params['q'] = label;

      uri = Uri.https('maps.apple.com', '/', params);
    } else {
      uri = Uri.https('www.google.com', '/maps/search/',
          {'api': '1', 'query': '$latitude,$longitude'});
    }

    return uri;
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> errorHandlerForOpen(
      LaunchType type) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to open ${type.name} app'),
      ),
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      errorHandlerForLaunch(LaunchType type) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to launch ${type.name} app'),
      ),
    );
  }
}
