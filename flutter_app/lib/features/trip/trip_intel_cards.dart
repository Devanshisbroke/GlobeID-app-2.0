import 'package:flutter/material.dart';
import '../../app/theme/app_tokens.dart';
import '../../widgets/glass_surface.dart';

/// Weather forecast card for trip detail — deterministic seasonal data.
class TripWeatherCard extends StatelessWidget {
  const TripWeatherCard({super.key, required this.destination, this.month});
  final String destination;
  final int? month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = month ?? DateTime.now().month;
    final data = _seasonalData(destination, m);
    return GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            gradient: LinearGradient(colors: [const Color(0xFF0EA5E9).withValues(alpha: 0.3), const Color(0xFF0EA5E9).withValues(alpha: 0.08)]),
          ), child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF0EA5E9), size: 18)),
          const SizedBox(width: AppTokens.space3),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('WEATHER FORECAST', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.4, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            Text(destination, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ]),
        const SizedBox(height: AppTokens.space3),
        SizedBox(height: 80, child: Row(children: [
          for (var i = 0; i < data.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _DayCol(day: data[i])),
          ],
        ])),
      ]),
    );
  }

  List<_DayData> _seasonalData(String dest, int month) {
    // Deterministic seasonal averages
    final base = (dest.hashCode.abs() % 15) + 10;
    final seasonal = (month >= 6 && month <= 8) ? 8 : (month >= 12 || month <= 2) ? -5 : 3;
    return List.generate(5, (i) => _DayData(
      label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][i],
      temp: base + seasonal + (i * 2 - 4),
      icon: i % 3 == 0 ? Icons.cloud_rounded : i % 3 == 1 ? Icons.wb_sunny_rounded : Icons.grain_rounded,
      rain: i % 3 == 2 ? '${20 + i * 10}%' : null,
    ));
  }
}

class _DayData { const _DayData({required this.label, required this.temp, required this.icon, this.rain}); final String label; final int temp; final IconData icon; final String? rain; }

class _DayCol extends StatelessWidget {
  const _DayCol({required this.day});
  final _DayData day;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(day.label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      const SizedBox(height: 4),
      Icon(day.icon, size: 20, color: day.icon == Icons.wb_sunny_rounded ? const Color(0xFFFBBF24) : theme.colorScheme.onSurface.withValues(alpha: 0.55)),
      const SizedBox(height: 4),
      Text('${day.temp}°', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      if (day.rain != null) Text(day.rain!, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: const Color(0xFF0EA5E9))),
    ]);
  }
}

/// Timezone awareness card — home vs destination time + jet lag.
class TripTimezoneCard extends StatelessWidget {
  const TripTimezoneCard({super.key, required this.origin, required this.destination, this.offsetHours = 0});
  final String origin, destination;
  final int offsetHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final destTime = now.add(Duration(hours: offsetHours));
    final jetLag = offsetHours.abs() > 5 ? 'Severe' : offsetHours.abs() > 2 ? 'Moderate' : 'Minimal';
    final dir = offsetHours > 0 ? 'East' : offsetHours < 0 ? 'West' : 'Same';
    return GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(children: [
        Row(children: [
          Expanded(child: _TimeCol(city: origin, time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}', label: 'HOME', tone: theme.colorScheme.primary)),
          Column(children: [
            Icon(Icons.compare_arrows_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            Text('${offsetHours >= 0 ? '+' : ''}${offsetHours}h', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
          ]),
          Expanded(child: _TimeCol(city: destination, time: '${destTime.hour.toString().padLeft(2, '0')}:${destTime.minute.toString().padLeft(2, '0')}', label: 'DESTINATION', tone: const Color(0xFFEC4899))),
        ]),
        const SizedBox(height: AppTokens.space2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Jet lag: $jetLag · Direction: $dir', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45), fontWeight: FontWeight.w600,
          )),
        ]),
      ]),
    );
  }
}

class _TimeCol extends StatelessWidget {
  const _TimeCol({required this.city, required this.time, required this.label, required this.tone});
  final String city, time, label; final Color tone;
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
      const SizedBox(height: 4),
      Text(time, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: tone, fontFeatures: const [FontFeature.tabularFigures()])),
      Text(city, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

/// Visa requirements card — deterministic lookup.
class TripVisaCard extends StatelessWidget {
  const TripVisaCard({super.key, required this.citizenship, required this.destination});
  final String citizenship, destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final req = _lookup(citizenship, destination);
    final color = req.color;
    return GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.06)]),
        ), child: Icon(req.icon, color: color, size: 22)),
        const SizedBox(width: AppTokens.space3),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(req.status, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(req.detail, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: color.withValues(alpha: 0.12),
        ), child: Text(req.badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  _VisaReq _lookup(String from, String to) {
    // Deterministic sim based on string hash
    final h = (from.hashCode ^ to.hashCode).abs() % 4;
    return switch (h) {
      0 => _VisaReq('Visa Free', '90-day stay, valid passport required', 'FREE', const Color(0xFF22C55E), Icons.check_circle_rounded),
      1 => _VisaReq('e-Visa', 'Apply online 72h before departure', 'E-VISA', const Color(0xFF0EA5E9), Icons.language_rounded),
      2 => _VisaReq('Visa on Arrival', 'Available at airport, \$25 fee', 'VOA', const Color(0xFFF59E0B), Icons.flight_land_rounded),
      _ => _VisaReq('Visa Required', 'Consular application needed, 10+ days', 'REQUIRED', const Color(0xFFEF4444), Icons.warning_rounded),
    };
  }
}

class _VisaReq { const _VisaReq(this.status, this.detail, this.badge, this.color, this.icon); final String status, detail, badge; final Color color; final IconData icon; }
