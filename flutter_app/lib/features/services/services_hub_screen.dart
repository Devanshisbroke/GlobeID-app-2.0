import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';

class ServicesHubScreen extends ConsumerWidget {
  const ServicesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final services = [
      _Svc('Hotels', '/services/hotels', Icons.hotel_rounded,
          const Color(0xFF7E22CE)),
      _Svc('Rides', '/services/rides', Icons.directions_car_rounded,
          const Color(0xFFEA580C)),
      _Svc('Food', '/services/food', Icons.restaurant_rounded,
          const Color(0xFFE11D48)),
      _Svc('Activities', '/services/activities', Icons.local_activity_rounded,
          const Color(0xFF059669)),
      _Svc('Transport', '/services/transport', Icons.train_rounded,
          const Color(0xFF1D4ED8)),
      _Svc('Vault', '/vault', Icons.shield_moon_rounded,
          const Color(0xFFD97706)),
      _Svc('Receipt', '/receipt', Icons.receipt_long_rounded,
          const Color(0xFF06B6D4)),
      _Svc('Loyalty', '/passport-book', Icons.workspace_premium_rounded,
          const Color(0xFFA855F7)),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space5,
        MediaQuery.of(context).padding.top + AppTokens.space5,
        AppTokens.space5,
        AppTokens.space9 + 16,
      ),
      children: [
        Text('Services', style: theme.textTheme.headlineLarge),
        Text('Everything you need on the road',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppTokens.space5),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppTokens.space3,
            crossAxisSpacing: AppTokens.space3,
            childAspectRatio: 1.05,
          ),
          itemCount: services.length,
          itemBuilder: (_, i) => _ServiceTile(svc: services[i])
              .animate()
              .fadeIn(delay: Duration(milliseconds: 30 * i))
              .slideY(begin: 0.06, end: 0),
        ),
      ],
    );
  }
}

class _Svc {
  const _Svc(this.name, this.path, this.icon, this.tone);
  final String name;
  final String path;
  final IconData icon;
  final Color tone;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.svc});
  final _Svc svc;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(svc.path),
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            border: Border.all(color: svc.tone.withValues(alpha: 0.30)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                svc.tone.withValues(alpha: 0.18),
                svc.tone.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: svc.tone.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                ),
                child: Icon(svc.icon, color: svc.tone, size: 26),
              ),
              Text(svc.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
