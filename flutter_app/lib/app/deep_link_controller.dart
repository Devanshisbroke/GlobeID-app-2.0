import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeepLinkController extends ConsumerStatefulWidget {
  const DeepLinkController({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<DeepLinkController> createState() => _DeepLinkControllerState();
}

class _DeepLinkControllerState extends ConsumerState<DeepLinkController> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final initial = await _appLinks.getInitialLink();
    if (!mounted) return;
    if (initial != null) _route(initial);
    _sub = _appLinks.uriLinkStream.listen(_route);
  }

  void _route(Uri uri) {
    final target = _targetFor(uri);
    if (target == null || !mounted) return;
    widget.router.push(target);
  }

  String? _targetFor(Uri uri) {
    if (uri.scheme != 'globeid') return null;
    final segments = [
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ];
    if (segments.length < 2) return null;
    final id = Uri.encodeComponent(segments[1]);
    return switch (segments.first) {
      'trip' => '/trip/$id',
      'pass' => '/pass/$id',
      'scan' => '/scan',
      'wallet' => '/wallet',
      _ => null,
    };
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
