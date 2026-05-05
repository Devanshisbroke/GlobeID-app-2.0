import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

/// Shared list scaffold for service sub-screens (hotels / rides / food /
/// activities / transport). Each sub-screen passes a fetcher that returns
/// a List of `{title, subtitle, price?, rating?}` maps.
class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.fetcher,
    this.tone,
  });

  final String title;
  final IconData icon;
  final Color? tone;
  final Future<List<Map<String, dynamic>>> Function() fetcher;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  late Future<List<Map<String, dynamic>>> _future = widget.fetcher();

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _future = widget.fetcher();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    return PageScaffold(
      title: widget.title,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(tone),
                      ),
                    ),
                  ),
                ],
              );
            }
            if (snap.hasError) {
              return EmptyState(
                title: '${widget.title} unavailable',
                message: snap.error.toString(),
                icon: Icons.cloud_off_rounded,
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return EmptyState(
                title: 'Nothing nearby',
                message:
                    'Tell us where you\'re heading and we\'ll find ${widget.title.toLowerCase()}.',
                icon: widget.icon,
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                AnimatedAppearance(
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tone.withValues(alpha: 0.32),
                        tone.withValues(alpha: 0.08),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          child:
                              Icon(widget.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  )),
                              Text('${items.length} nearby',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                for (var i = 0; i < items.length; i++)
                  AnimatedAppearance(
                    delay: Duration(milliseconds: 60 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.space3),
                      child: _ServiceRow(
                        data: items[i],
                        icon: widget.icon,
                        tone: tone,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.data,
    required this.icon,
    required this.tone,
  });
  final Map<String, dynamic> data;
  final IconData icon;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = (data['rating'] as num?)?.toDouble();
    return Pressable(
      scale: 0.98,
      onTap: () => HapticFeedback.lightImpact(),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                gradient: LinearGradient(
                  colors: [
                    tone.withValues(alpha: 0.32),
                    tone.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Icon(icon, color: tone, size: 24),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title']?.toString() ?? '',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  if (data['subtitle'] != null) ...[
                    const SizedBox(height: 2),
                    Text(data['subtitle'].toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        )),
                  ],
                  if (rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (data['price'] != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  color: tone.withValues(alpha: 0.12),
                  border: Border.all(color: tone.withValues(alpha: 0.32)),
                ),
                child: Text(data['price'].toString(),
                    style: TextStyle(
                      color: tone,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ),
          ],
        ),
      ),
    );
  }
}
