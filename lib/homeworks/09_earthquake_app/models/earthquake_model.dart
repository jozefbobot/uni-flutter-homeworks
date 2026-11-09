class EarthquakeModel {
  const EarthquakeModel(this.earthquakes);

  final List<Earthquake> earthquakes;

  factory EarthquakeModel.fromJson(Object? json) {
    if (json case {'features': final List<Object?> features}) {
      return EarthquakeModel(
        List.unmodifiable(features.map(Earthquake.fromJson)),
      );
    }
    throw const FormatException('Missing GeoJSON features');
  }
}

class Earthquake {
  const Earthquake({
    this.place,
    this.title,
    this.time,
    this.magnitude,
    this.alert,
  });

  final String? place;
  final String? title;
  final DateTime? time;
  final double? magnitude;
  final String? alert;

  factory Earthquake.fromJson(Object? feature) {
    if (feature case {'properties': final Map<String, Object?> properties}) {
      final place = properties['place'];
      final title = properties['title'];
      final timestamp = properties['time'];
      final magnitude = properties['mag'];
      final alert = properties['alert'];
      return Earthquake(
        place: place is String ? place : null,
        title: title is String ? title : null,
        time: timestamp is num
            ? DateTime.fromMillisecondsSinceEpoch(
                timestamp.toInt(),
                isUtc: true,
              )
            : null,
        magnitude: magnitude is num ? magnitude.toDouble() : null,
        alert: alert is String ? alert : null,
      );
    }
    throw const FormatException('Missing earthquake properties');
  }
}
