import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/earthquake_model.dart';

enum EarthquakeOrder {
  newest('time', 'Newest first'),
  oldest('time-asc', 'Oldest first'),
  highestMagnitude('magnitude', 'Highest magnitude first'),
  lowestMagnitude('magnitude-asc', 'Lowest magnitude first');

  const EarthquakeOrder(this.queryValue, this.label);

  final String queryValue;
  final String label;
}

class AppDataProvider extends ChangeNotifier {
  AppDataProvider({http.Client? client}) : _client = client ?? http.Client() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day - 1);
    _endDate = DateUtils.dateOnly(now);
  }

  static const _nearbyRadiusKm = '300';
  static const _timeout = Duration(seconds: 20);

  final http.Client _client;
  List<Earthquake> _earthquakes = const [];
  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;
  Position? _position;
  late DateTime _startDate;
  late DateTime _endDate;
  double _minimumMagnitude = 4;
  EarthquakeOrder _order = EarthquakeOrder.newest;
  int _requestId = 0;
  bool _disposed = false;

  List<Earthquake> get earthquakes => _earthquakes;
  bool get isLoading => _isLoading;
  bool get isLocating => _isLocating;
  bool get usesLocation => _position != null;
  String? get errorMessage => _errorMessage;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  double get minimumMagnitude => _minimumMagnitude;
  EarthquakeOrder get order => _order;

  Future<void> setOrder(EarthquakeOrder order) async {
    if (_order == order) return;
    _order = order;
    await refresh();
  }

  Future<void> setMinimumMagnitude(double magnitude) async {
    if (_minimumMagnitude == magnitude) return;
    _minimumMagnitude = magnitude;
    await refresh();
  }

  Future<void> applyDateRange(DateTimeRange range) {
    _startDate = DateUtils.dateOnly(range.start);
    _endDate = DateUtils.dateOnly(range.end);
    return refresh();
  }

  Future<String?> setUseLocation(bool enabled) async {
    if (_disposed || _isLocating || enabled == usesLocation) return null;
    if (!enabled) {
      _position = null;
      await refresh();
      return null;
    }

    _isLocating = true;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Turn on location services to find nearby earthquakes.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Allow location access in your device settings.';
      }
      if (permission == LocationPermission.denied) {
        return 'Location permission was denied.';
      }

      final locationSettings =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(forceLocationManager: true, timeLimit: _timeout)
          : const LocationSettings(timeLimit: _timeout);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (_disposed) return null;
      _position = position;
    } on TimeoutException {
      return 'Finding your location timed out. Try again.';
    } on Exception {
      return 'Your location could not be determined. Try again.';
    } finally {
      _isLocating = false;
      if (!_disposed) notifyListeners();
    }

    await refresh();
    return null;
  }

  Uri _queryUri() {
    // USGS end times are inclusive. Convert the full local day to UTC.
    final endOfDay = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day + 1,
    ).subtract(const Duration(milliseconds: 1));
    return Uri.https('earthquake.usgs.gov', '/fdsnws/event/1/query', {
      'format': 'geojson',
      'eventtype': 'earthquake',
      'starttime': _startDate.toUtc().toIso8601String(),
      'endtime': endOfDay.toUtc().toIso8601String(),
      if (_minimumMagnitude > 0) 'minmagnitude': '$_minimumMagnitude',
      'orderby': _order.queryValue,
      'limit': '500',
      if (_position case final position?) ...{
        'latitude': '${position.latitude}',
        'longitude': '${position.longitude}',
        'maxradiuskm': _nearbyRadiusKm,
      },
    });
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final requestId = ++_requestId;
    final uri = _queryUri();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    List<Earthquake> earthquakes = const [];
    String? error;
    try {
      final response = await _client.get(uri).timeout(_timeout);
      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          earthquakes = EarthquakeModel.fromJson(json).earthquakes;
        case 204:
          break;
        default:
          error = 'USGS returned an error (${response.statusCode}).';
      }
    } on TimeoutException {
      error = 'The request timed out. Try again.';
    } on FormatException {
      error = 'The USGS response could not be read.';
    } on http.ClientException {
      error = 'Could not reach USGS. Check your internet connection.';
    }

    // A newer filter or sort request may have completed first.
    if (_disposed || requestId != _requestId) return;
    _earthquakes = earthquakes;
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }
}
