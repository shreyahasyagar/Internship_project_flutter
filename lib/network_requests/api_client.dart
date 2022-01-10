import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'exceptions.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String apiKey = String.fromEnvironment('API_KEY',
      defaultValue: '54ca993b6e8040d883f8da1753bc5f3d');
  final String _newsUrl = "http://newsapi.org/v2/everything?";
  final String _statsUrl = "https://disease.sh/v2/";
  final String _query = "q=covid%2019%20vaccine";
  final String _limit = "pageSize=10&page=1";

  String get query => _query;
  String get newsUrl => _newsUrl;
  String get statsUrl => _statsUrl;
  String get limit => _limit;
}

//https://newsapi.org/v2/everything?q=covid%2019%20vaccine&apiKey=54ca993b6e8040d883f8da1753bc5f3d
class ApiClient {
  ApiService _apiService = ApiService();

  getNewsResponse(String value) async {
    String endpoint = _getNewsEndpoint(value);
    String url = _apiService.newsUrl +
        _apiService.query +
        "&" +
        _apiService.limit +
        "&" +
        endpoint +
        "&" +
        ApiService.apiKey;
    try {
      var response = await http.get(url);
      var json = jsonDecode(response.body);
      if (json['status'] == "ok") {
        return json;
      } else if (json['status'] == "error") {
        throw FetchDataException(json['code'] + json['message']);
      }
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
  }

  getStatsResponse(StateLocation stateLocation,
      {String code = "", bool yesterday = false}) async {
    String endpoint = _getStatsEndpoint(
        location: stateLocation, code: code, yesterday: yesterday);
    String url = _apiService.statsUrl + endpoint;
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        // ignore: non_constant_identifier_names
        var Json = json.decode(response.body);
        if (stateLocation == StateLocation.TOP_FIVE) {
          return Json.sublist(0, 6);
        }
        return Json;
      } else {
        throw FetchDataException("Failed to load stats");
      }
    } on SocketException {
      throw FetchDataException("No internet connection");
    }
  }

  _getStatsEndpoint(
      {@required String code,
      bool yesterday,
      @required StateLocation location}) {
    if (location == StateLocation.GLOBAL) return "all?yesterday=$yesterday";
    String endpoint = "countries";

    if (location == StateLocation.SPECIFIC) {
      endpoint += "/" + code + "?strict=false&";
    } else if (location == StateLocation.TOP_FIVE) {
      endpoint += "?sort=cases&";
    } else if (location == StateLocation.ALL) {
      endpoint += "?";
    }
    return endpoint + "allowNull=false&yesterday=$yesterday";
  }

  _getNewsEndpoint(String value) {
    if (value == "Last Week") {
      return "from=${_getDate(7)}&sortBy=popular";
    } else if (value == "Last 15") {
      return "from=${_getDate(15)}&sortBy=popular";
    } else if (value == "Last Month") {
      return "from=${_getDate(30)}&sortBy=popular";
    }
    return "from=${_getDate(10)}&sortBy=$value";
  }

  _getDate(int days) {
    var now = DateTime.now();
    now = now.subtract(Duration(days: days));
    var date = now.toString();
    date = date.split(" ")[0];
    return date;
  }
}

enum StateLocation { GLOBAL, SPECIFIC, ALL, TOP_FIVE }
