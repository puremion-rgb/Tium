/// 정원(화단)에서 한 번에 키울 수 있는 퀘스트 수.
/// 화단이 가장 보기 좋은 개수(앞줄 4 + 뒷줄 4)이자, 습관을 한 번에 너무 많이 잡지 않게 하는 장치.
/// 쉬는 중인 퀘스트는 화단에서 빠지므로 세지 않는다.
const maxActiveQuests = 8;

/// 화단이 가득 찼는데 퀘스트를 추가하거나 다시 시작하려 할 때
class GardenFullException implements Exception {
  const GardenFullException();

  @override
  String toString() => '정원이 가득 찼어요 (최대 $maxActiveQuests개)';
}
