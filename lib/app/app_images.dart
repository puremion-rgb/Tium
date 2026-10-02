import '../models/plant.dart';
import '../models/weather.dart';

/// 이미지 경로는 전부 여기서만 관리한다.
/// 그림을 바꿀 때는 같은 이름으로 파일만 덮어쓰거나, 이 파일의 경로만 고치면 된다.
class AppImages {
  AppImages._();

  static const _bg = 'assets/images/backgrounds';
  static const _char = 'assets/images/characters';

  static String garden(WeatherKind kind) => switch (kind) {
        WeatherKind.sunny => '$_bg/garden_sunny.webp',
        WeatherKind.cloudy => '$_bg/garden_cloudy.webp',
        WeatherKind.rain => '$_bg/garden_rain.webp',
        WeatherKind.snow => '$_bg/garden_snow.webp',
        WeatherKind.night => '$_bg/garden_night.webp',
      };

  static String plant(PlantKind kind, GrowthStage stage) =>
      'assets/images/plants/${kind.name}_${stage.name}.svg';

  static const characterFront = '$_char/front.webp';
  static const characterReading = '$_char/reading_with_dog.webp';
  static const avatar = '$_char/avatar.webp';
  static const startIllustration = 'assets/images/illustrations/start_watering.webp';
}
