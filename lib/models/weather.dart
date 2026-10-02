enum WeatherKind {
  sunny('맑음'),
  cloudy('흐림'),
  rain('비'),
  snow('눈'),
  night('맑은 밤');

  const WeatherKind(this.label);
  final String label;

  /// Open-Meteo의 WMO weather_code를 정원 날씨 5종으로 묶는다.
  static WeatherKind fromWmo(int code, {required bool isDay}) {
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return WeatherKind.snow;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95) return WeatherKind.rain;
    if (code == 2 || code == 3 || code == 45 || code == 48) return isDay ? WeatherKind.cloudy : WeatherKind.night;
    return isDay ? WeatherKind.sunny : WeatherKind.night;
  }
}

class Weather {
  const Weather({required this.kind, required this.temperature, required this.city});

  final WeatherKind kind;
  final double temperature;
  final String city;

  String get temperatureText => '${temperature.round()}°C';
}
