import 'dart:convert';

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
    final response = await http.post(Uri.parse(url as String),
        headers: <String, String>{
          "Content-Type": "application/json",
        },
        body: jsonEncode(<String, dynamic>{
          "ids": keys,
          "days": daysToFetch,
        }));

    if (response.statusCode == 200) {
      var out = await jsonDecode(response.body)["results"];
      logger.i('Found ${out.length} reports');
      return out;
    } else {
      throw Exception(
          "Failed to fetch location reports with statusCode:${response.statusCode}\n\n Response:\n$response");
    }
  }
}
