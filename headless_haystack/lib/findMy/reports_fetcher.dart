import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ReportsFetcher {
  /// Fetches the location reports corresponding to the given hashed advertisement
  /// key.
  /// Throws [Exception] if no answer was received.
  ///
  static var logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static Future<List> fetchLocationReports(
      Iterable<String> hashedAdvertisementKeys, int daysToFetch,
      [String? url]) async {
    var keys = hashedAdvertisementKeys.toList(growable: false);
    logger.i('Using ${keys.length} key(s) to ask webservice');
    var httpClient = HttpClient();
    /*Ignore certificate errors*/
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    final request = await httpClient.postUrl(Uri.parse(url as String));
    var body = jsonEncode(<String, dynamic>{
      "ids": keys,
      "days": daysToFetch,
    });
    request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
    request.headers
        .set(HttpHeaders.contentLengthHeader, utf8.encode(body).length);
    request.write(body);
    final response = await request.close();

    if (response.statusCode == 200) {
      String body = await response.transform(utf8.decoder).join();
      var out = await jsonDecode(body)["results"];
      return out;
    } else {
      throw Exception(
          "Failed to fetch location reports with statusCode:${response.statusCode}\n\n Response:\n$response");
    }
  }
}
