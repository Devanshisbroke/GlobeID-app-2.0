/// Dart port of `src/lib/predictiveDeparture.ts`. Computes a
/// "leave home by" time given a flight departure + airport overhead.
class LeaveByEstimate {
  const LeaveByEstimate({
    required this.leaveBy,
    required this.travelTimeMinutes,
    required this.bufferMinutes,
  });

  final DateTime leaveBy;
  final int travelTimeMinutes;
  final int bufferMinutes;
}

LeaveByEstimate predictLeaveBy({
  required DateTime departureLocal,
  int travelTimeMinutes = 30,
  int bufferMinutes = 90,
  bool isInternational = false,
  int trafficPenaltyMinutes = 0,
}) {
  final extra = isInternational ? 30 : 0;
  final total =
      travelTimeMinutes + bufferMinutes + extra + trafficPenaltyMinutes;
  return LeaveByEstimate(
    leaveBy: departureLocal.subtract(Duration(minutes: total)),
    travelTimeMinutes: travelTimeMinutes + trafficPenaltyMinutes,
    bufferMinutes: bufferMinutes + extra,
  );
}
