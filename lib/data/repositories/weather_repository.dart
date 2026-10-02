import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/weather.dart';

abstract interface class WeatherRepository {
  Future<Weather> fetch(String city);
}

/// 도시 이름 → 위도·경도 (도시 선택 화면 목록과 같다)
const cityCoordinates = <String, (double, double)>{
  '서울': (37.5665, 126.9780),
  '부산': (35.1796, 129.0756),
  '대구': (35.8714, 128.6014),
  '인천': (37.4563, 126.7052),
  '광주': (35.1595, 126.8526),
  '대전': (36.3504, 127.3845),
  '울산': (35.5384, 129.3114),
  '세종': (36.4800, 127.2890),
  '제주': (33.4996, 126.5312),
};

/// Open-Meteo (API 키 필요 없음)
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Weather> fetch(String city) async {
    final (lat, lon) = cityCoordinates[city] ?? cityCoordinates['서울']!;
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'current': 'temperature_2m,weather_code,is_day',
      'timezone': 'Asia/Seoul',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw http.ClientException('날씨를 불러오지 못했어요 (${res.statusCode})', uri);
    }
    final current = (jsonDecode(res.body) as Map<String, dynamic>)['current'] as Map<String, dynamic>;
    return Weather(
      city: city,
      temperature: (current['temperature_2m'] as num).toDouble(),
      kind: WeatherKind.fromWmo((current['weather_code'] as num).toInt(), isDay: current['is_day'] == 1),
    );
  }
}

class FakeWeatherRepository implements WeatherRepository {
  const FakeWeatherRepository({this.kind = WeatherKind.sunny});
  final WeatherKind kind;

  @override
  Future<Weather> fetch(String city) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    const temps = {
      WeatherKind.sunny: 18.0,
      WeatherKind.cloudy: 15.0,
      WeatherKind.rain: 14.0,
      WeatherKind.snow: -2.0,
      WeatherKind.night: 12.0,
    };
    return Weather(kind: kind, temperature: temps[kind]!, city: city);
  }
}
