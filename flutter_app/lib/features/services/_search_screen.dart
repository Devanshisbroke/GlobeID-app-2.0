import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';

/// Shared list scaffold for service sub-screens (hotels / rides / food /
/// activities / transport). Each sub-screen passes a fetcher that returns
/// a List of `{title, subtitle, price?}` maps.
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
    setState(() {
      _future = widget.fetcher();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: widget.title,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTokens.space2),
              itemBuilder: (_, i) {
                final m = items[i];
                return GlassSurface(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (widget.tone ?? theme.colorScheme.primary)
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusLg),
                        ),
                        child: Icon(widget.icon,
                            color: widget.tone ?? theme.colorScheme.primary),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['title']?.toString() ?? '',
                                style: theme.textTheme.titleSmall),
                            Text(m['subtitle']?.toString() ?? '',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (m['price'] != null)
                        Text(m['price'].toString(),
                            style: theme.textTheme.titleSmall),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
