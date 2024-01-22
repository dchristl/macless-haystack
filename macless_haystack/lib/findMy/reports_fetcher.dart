import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ReportsFetcher {
  /// Fetches the location reports corresponding to the given hashed advertisement
  /// key.
  /// Throws [Exception] if no answer was received.
  ///
  static var logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static Future<List> fetchLocationReports(
      Iterable<String> hashedAdvertisementKeys,
      int daysToFetch,
      String url,
      String user,
      String pass) async {
    var keys = hashedAdvertisementKeys.toList(growable: false);
    logger.i('Using ${keys.length} key(s) to ask webservice');

    String? credentials;
    if (user.trim().isNotEmpty || pass.trim().isNotEmpty) {
      credentials = 'Basic ${base64.encode(utf8.encode("$user:$pass"))}';
    }

    if (kIsWeb) {
      Map<String, String> requestHeaders = {
        "Content-Type": "application/json",
      };
      if (credentials != null) {
        requestHeaders['Authorization'] = credentials;
      }

      final response = await http.post(Uri.parse(url),
          headers: requestHeaders,
          body: jsonEncode(<String, dynamic>{
            "ids": keys,
            "days": daysToFetch,
          }));
      if (response.statusCode == 401) {
        throw Exception("Authentication failure. User/password wrong");
      }
      if (response.statusCode == 200) {
        var out = await jsonDecode(response.body)["results"];
        logger.i('Found ${out.length} reports');
        return out;
      } else {
        throw Exception(
            "Failed to fetch location reports with statusCode:${response.statusCode}\n\n Response:\n$response");
      }
    } else {
      var httpClient = HttpClient();
      /*Ignore certificate errors*/
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.postUrl(Uri.parse(url));
      var body = jsonEncode(<String, dynamic>{
        "ids": keys,
        "days": daysToFetch,
      });
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      if (credentials != null) {
        request.headers.set(HttpHeaders.authorizationHeader, credentials);
      }

      request.headers
          .set(HttpHeaders.contentLengthHeader, utf8.encode(body).length);
      request.write(body);
      final response = await request.close();
      if (response.statusCode == 401) {
        throw Exception("Authentication failure. User/password wrong");
      }
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
}
