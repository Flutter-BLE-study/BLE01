/// 사이클 모델 (보드에서 주는 정보)
class CycleModel {
  // total:69.30/speed:6.20
  double total; // 총 운동 거리(km)
  double speed; // 현재 속도(m/s)

  CycleModel({
    required this.total,
    required this.speed,
  });

  factory CycleModel.fromString(String msg) {
    List<String> splitMsg = msg.split("/");
    return CycleModel(
      total: double.parse(splitMsg[0].split(":")[1]),
      speed: double.parse(splitMsg[1].split(":")[1]),
    );
  }

  @override
  String toString() {
    return
      '''[total]:$total [speed]:$speed
''';
  }
}