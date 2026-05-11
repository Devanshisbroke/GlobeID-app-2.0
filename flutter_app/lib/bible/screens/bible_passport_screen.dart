import 'package:flutter/material.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_buttons.dart';
import '../chrome/bible_pressable.dart';
import '../chrome/bible_premium_card.dart';
import '../chrome/bible_scaffold.dart';
import '../chrome/bible_widgets.dart';
import '../living/bible_spatial_depth.dart';
import '../materials/bible_foil.dart';
import '../materials/bible_paper.dart';

/// GlobeID — **Identity / Passport** (§11.3 _The Holographic Document_).
///
/// Registers: Stillness. Spine: Identity.
///
/// Spec:
///   * Bio page rendered on Vellum Bone paper substrate, hairline thin.
///   * Photo well lifts on tilt — gyro-reactive foil specular sheen.
///   * Visa rail below: drawer reveals one chip per country, each
///     coloured by its sovereign tone palette.
///   * Page-turn affordance via long-press → bottom-of-card chevron.
class BiblePassportScreen extends StatefulWidget {
  const BiblePassportScreen({super.key});

  @override
  State<BiblePassportScreen> createState() => _BiblePassportScreenState();
}

class _BiblePassportScreenState extends State<BiblePassportScreen> {
  int _page = 0;
  static const _pages = [
    'biographical',
    'machine readable',
    'visa stamps',
    'biometric record',
  ];

  @override
  Widget build(BuildContext context) {
    return BiblePageScaffold(
      emotion: BEmotion.stillness,
      tone: B.diplomaticGarnet.withValues(alpha: 0.06),
      density: BDensity.concourse,
      eyebrow: '— globeid · diplomatic credential —',
      title: 'Passport',
      trailing: const BibleStatusPill(
        label: 'verified',
        tone: B.foilGold,
        breathing: true,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PassportBookletCard(page: _page),
          const SizedBox(height: B.space3),
          _PageNavigator(
            page: _page,
            onChanged: (i) => setState(() => _page = i),
            labels: _pages,
          ),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'visa drawer',
            title: 'Open stamps',
          ),
          const _VisaDrawer(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'credential gallery',
            title: '12 issuers',
          ),
          const _CredentialGallery(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'tier ladder',
            title: 'Identity score 92',
          ),
          _TierLadder(),
          const SizedBox(height: B.space6),
        ],
      ),
    );
  }
}

class _PassportBookletCard extends StatelessWidget {
  const _PassportBookletCard({required this.page});
  final int page;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: BibleSpatialDepth(
      maxTravelPx: 8,
      slots: [
        // Slot 0 — soft shadow halo behind booklet.
        Center(
          child: Container(
            width: 320,
            height: 460,
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(B.rHero),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 48,
                  offset: const Offset(0, 26),
                ),
              ],
            ),
          ),
        ),
        // Slot 2 — paper booklet itself.
        Center(
          child: SizedBox(
            width: 320,
            height: 460,
            child: BiblePaper(
              radius: B.rHero,
              substrate: B.vellumBone,
              elevation: 1.2,
              padding: EdgeInsets.zero,
              child: _BookletContents(page: page),
            ),
          ),
        ),
        // Slot 3 — foil ribbon top strap.
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 28),
            child: SizedBox(
              width: 240,
              height: 36,
              child: BibleFoil(
                radius: 20,
                tone: B.foilGold,
                padding: EdgeInsets.zero,
                hologram: true,
                child: Center(
                  child: BText.eyebrow(
                    'gid · diplomatic',
                    color: const Color(0xFF2A1A06),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }
}

class _BookletContents extends StatelessWidget {
  const _BookletContents({required this.page});
  final int page;
  @override
  Widget build(BuildContext context) {
    switch (page) {
      case 0:
        return _BioPage();
      case 1:
        return _MrzPage();
      case 2:
        return _StampPage();
      default:
        return _BiometricPage();
    }
  }
}

class _BioPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(B.space6, 72, B.space5, B.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo well — would normally be a real image; placeholder grain.
              Container(
                width: 88,
                height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: B.tarmacSlate.withValues(alpha: 0.92),
                  border: Border.all(
                    color: B.foilGold.withValues(alpha: 0.6),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_rounded,
                  size: 56,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: B.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText.eyebrow(
                      'surname / nom',
                      color: const Color(0xFF6A5742),
                    ),
                    BText.display('BARAI', size: 18, color: const Color(0xFF1A1305)),
                    const SizedBox(height: B.space2),
                    BText.eyebrow(
                      'given names / prénoms',
                      color: const Color(0xFF6A5742),
                    ),
                    BText.display('DEVANSH', size: 18, color: const Color(0xFF1A1305)),
                    const SizedBox(height: B.space2),
                    BText.eyebrow(
                      'nationality',
                      color: const Color(0xFF6A5742),
                    ),
                    BText.mono('INDIA · IND', color: const Color(0xFF1A1305)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B.space4),
          Row(
            children: [
              Expanded(
                child: _BioField(
                  label: 'date of birth',
                  value: '14 SEP 1999',
                ),
              ),
              Expanded(
                child: _BioField(label: 'sex', value: 'M'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _BioField(
                  label: 'place of birth',
                  value: 'KOLKATA',
                ),
              ),
              Expanded(
                child: _BioField(
                  label: 'authority',
                  value: 'MEA · NEW DELHI',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _BioField(
                  label: 'date of issue',
                  value: '02 JAN 2023',
                ),
              ),
              Expanded(
                child: _BioField(
                  label: 'date of expiry',
                  value: '01 JAN 2033',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BioField extends StatelessWidget {
  const _BioField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: B.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BText.eyebrow(label, color: const Color(0xFF6A5742)),
          const SizedBox(height: 2),
          BText.mono(value, color: const Color(0xFF1A1305), size: 13),
        ],
      ),
    );
  }
}

class _MrzPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(B.space6, 72, B.space5, B.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BText.eyebrow(
            'machine readable zone',
            color: const Color(0xFF6A5742),
          ),
          const SizedBox(height: B.space4),
          Container(
            padding: const EdgeInsets.all(B.space3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(B.rTile),
              color: Colors.black.withValues(alpha: 0.04),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BText.mono(
                  'P<INDBARAI<<DEVANSH<<<<<<<<<<<<<<<<<<<<<<<<',
                  size: 13,
                  color: const Color(0xFF1A1305),
                ),
                BText.mono(
                  'L901829834IND9909141M3301015<<<<<<<<<<<<<00',
                  size: 13,
                  color: const Color(0xFF1A1305),
                ),
              ],
            ),
          ),
          const SizedBox(height: B.space4),
          BText.caption(
            'Validated against ICAO 9303 standard. Read by 27 issuers.',
            color: const Color(0xFF6A5742),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _StampPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(B.space5, 72, B.space5, B.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BText.eyebrow('visa stamps', color: const Color(0xFF6A5742)),
          const SizedBox(height: B.space3),
          Wrap(
            spacing: B.space2,
            runSpacing: B.space2,
            children: const [
              _Stamp(country: 'JPN', date: '03·22', tone: Color(0xFF8E3340)),
              _Stamp(country: 'GBR', date: '07·22', tone: Color(0xFF274F87)),
              _Stamp(country: 'PRT', date: '11·22', tone: Color(0xFF22682C)),
              _Stamp(country: 'ISL', date: '02·23', tone: Color(0xFF1C5C82)),
              _Stamp(country: 'USA', date: '05·23', tone: Color(0xFF642A2A)),
              _Stamp(country: 'AUS', date: '09·23', tone: Color(0xFF6F3C00)),
              _Stamp(country: 'KOR', date: '01·24', tone: Color(0xFF512378)),
              _Stamp(country: 'CHE', date: '06·24', tone: Color(0xFF7A1C1C)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.country,
    required this.date,
    required this.tone,
  });
  final String country;
  final String date;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.04,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: B.space3,
          vertical: B.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tone, width: 1.4),
          color: tone.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BText.display(country, size: 13, color: tone),
            BText.mono(date, size: 10, color: tone),
          ],
        ),
      ),
    );
  }
}

class _BiometricPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(B.space6, 72, B.space5, B.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BText.eyebrow(
            'biometric record',
            color: const Color(0xFF6A5742),
          ),
          const SizedBox(height: B.space4),
          _BioField(label: 'face encoding', value: 'sha256:9af3…ec21'),
          _BioField(label: 'iris hash', value: 'sha256:1bd0…7a44'),
          _BioField(label: 'fingerprint', value: '4 of 4 enrolled'),
          _BioField(label: 'liveness', value: 'NIST PAD level 2'),
          const SizedBox(height: B.space3),
          BText.caption(
            'On-device biometrics. Never uploaded. Vault sealed.',
            color: const Color(0xFF6A5742),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _PageNavigator extends StatelessWidget {
  const _PageNavigator({
    required this.page,
    required this.onChanged,
    required this.labels,
  });
  final int page;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            BiblePressable(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: B.dQuick,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: B.space3,
                  vertical: B.space2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(B.rPill),
                  color: page == i
                      ? B.foilGold.withValues(alpha: 0.18)
                      : Colors.transparent,
                  border: Border.all(
                    color: page == i
                        ? B.foilGold.withValues(alpha: 0.50)
                        : B.hairlineLight,
                    width: 0.6,
                  ),
                ),
                child: BText.monoCap(
                  labels[i],
                  color: page == i ? B.foilGold : B.inkOnDarkLow,
                ),
              ),
            ),
            if (i != labels.length - 1) const SizedBox(width: B.space2),
          ],
        ],
      ),
    );
  }
}

class _VisaDrawer extends StatelessWidget {
  const _VisaDrawer();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _VisaChip(country: 'Japan', tone: Color(0xFF8E3340), expiry: '03·26'),
          _VisaChip(country: 'UK', tone: Color(0xFF274F87), expiry: '08·26'),
          _VisaChip(
            country: 'Schengen',
            tone: Color(0xFF22682C),
            expiry: '11·25',
          ),
          _VisaChip(country: 'USA', tone: Color(0xFF642A2A), expiry: '04·27'),
          _VisaChip(
            country: 'Australia',
            tone: Color(0xFF6F3C00),
            expiry: '09·26',
          ),
          _VisaChip(country: 'Korea', tone: Color(0xFF512378), expiry: '01·27'),
        ],
      ),
    );
  }
}

class _VisaChip extends StatelessWidget {
  const _VisaChip({
    required this.country,
    required this.tone,
    required this.expiry,
  });
  final String country;
  final Color tone;
  final String expiry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: B.space3),
      child: BiblePremiumCard(
        tone: tone,
        padding: const EdgeInsets.all(B.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BText.eyebrow('visa', color: tone),
            const SizedBox(height: B.space1),
            BText.title(country, size: 14),
            const Spacer(),
            BText.mono('valid → $expiry', color: B.inkOnDarkLow, size: 11),
          ],
        ),
      ),
    );
  }
}

class _CredentialGallery extends StatelessWidget {
  const _CredentialGallery();
  @override
  Widget build(BuildContext context) {
    final issuers = const <_Issuer>[
      _Issuer(
        name: 'MEA India',
        kind: 'Passport',
        tone: Color(0xFFFF8C00),
        icon: Icons.workspace_premium_rounded,
      ),
      _Issuer(
        name: 'Schengen',
        kind: 'Visa',
        tone: Color(0xFF22682C),
        icon: Icons.travel_explore_rounded,
      ),
      _Issuer(
        name: 'DVLA',
        kind: 'Driving licence',
        tone: B.polarBlue,
        icon: Icons.directions_car_rounded,
      ),
      _Issuer(
        name: 'IATA',
        kind: 'Frequent flyer · Plat',
        tone: B.jetCyan,
        icon: Icons.flight_takeoff_rounded,
      ),
      _Issuer(
        name: 'Bank IDX',
        kind: 'Treasury seal',
        tone: B.treasuryGreen,
        icon: Icons.account_balance_rounded,
      ),
      _Issuer(
        name: 'NHS',
        kind: 'Health record',
        tone: B.equatorTeal,
        icon: Icons.local_hospital_rounded,
      ),
    ];
    return Column(
      children: [
        for (final i in issuers)
          Padding(
            padding: const EdgeInsets.only(bottom: B.space2),
            child: BiblePremiumCard(
              tone: i.tone,
              padding: const EdgeInsets.all(B.space3),
              child: Row(
                children: [
                  BibleGlyphHalo(icon: i.icon, tone: i.tone, size: 36),
                  const SizedBox(width: B.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BText.title(i.name, size: 14),
                        BText.caption(i.kind, color: B.inkOnDarkMid),
                      ],
                    ),
                  ),
                  const BibleStatusPill(
                    label: 'sealed',
                    tone: B.foilGold,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Issuer {
  const _Issuer({
    required this.name,
    required this.kind,
    required this.tone,
    required this.icon,
  });
  final String name;
  final String kind;
  final Color tone;
  final IconData icon;
}

class _TierLadder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.foilGold,
      padding: const EdgeInsets.all(B.space4),
      child: Column(
        children: [
          Row(
            children: [
              BibleProgressArc(
                value: 0.92,
                tone: B.foilGold,
                diameter: 88,
                label: 'tier · iv',
              ),
              const SizedBox(width: B.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText.eyebrow('identity score', color: B.foilGold),
                    const SizedBox(height: B.space1),
                    BText.title('92 · Diplomatic', size: 17),
                    const SizedBox(height: B.space2),
                    BText.caption(
                      '8 points to tier V · expedited consular access.',
                      color: B.inkOnDarkMid,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B.space3),
          const BibleDivider(),
          const SizedBox(height: B.space3),
          BibleMagneticButton(
            label: 'View tier privileges',
            icon: Icons.workspace_premium_rounded,
            tone: B.foilGold,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
