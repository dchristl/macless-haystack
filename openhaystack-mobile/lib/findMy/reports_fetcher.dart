import 'dart:convert';

import 'package:http/http.dart' as http;

class ReportsFetcher {
  /// Fetches the location reports corresponding to the given hashed advertisement
  /// key.
  /// Throws [Exception] if no answer was received.
  static Future<List> fetchLocationReports(String hashedAdvertisementKey,
      [String? url]) async {
    final response = await http.post(Uri.parse(url as String),
        headers: <String, String>{
          "Content-Type": "application/json",
        },
        body: jsonEncode(<String, dynamic>{
          "ids": [hashedAdvertisementKey],
        }));

    if (response.statusCode == 200) {
      return await jsonDecode(response.body)["results"];
    } else {
      throw Exception(
          "Failed to fetch location reports with statusCode:${response.statusCode}\n\n Response:\n${response}");
    }
  }
}
