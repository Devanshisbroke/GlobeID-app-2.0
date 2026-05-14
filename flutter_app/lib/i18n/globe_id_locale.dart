import 'package:flutter/material.dart';

/// Phase 13a — GlobeID localization scaffold.
///
/// Five canonical locales. The brand is the chrome layer — strings
/// localize, the GLOBE · ID monogram and the foil-gold palette do
/// not. Mono-cap watermarks stay LTR even under RTL locales (Latin
/// trademark, not body copy).
enum GlobeIdLocale {
  enUS('en', 'US', 'English', 'ENGLISH · US', TextDirection.ltr),
  arSA('ar', 'SA', 'العربية', 'العربية · SA', TextDirection.rtl),
  zhCN('zh', 'CN', '简体中文', 'CHINESE · CN', TextDirection.ltr),
  esES('es', 'ES', 'Español', 'ESPAÑOL · ES', TextDirection.ltr),
  jaJP('ja', 'JP', '日本語', 'JAPANESE · JP', TextDirection.ltr);

  const GlobeIdLocale(
    this.languageCode,
    this.countryCode,
    this.nativeName,
    this.monoCapName,
    this.textDirection,
  );

  final String languageCode;
  final String countryCode;
  final String nativeName;
  final String monoCapName;
  final TextDirection textDirection;

  String get tag => '$languageCode-$countryCode';

  Locale toMaterialLocale() => Locale(languageCode, countryCode);

  static GlobeIdLocale fromTag(String tag) {
    for (final l in GlobeIdLocale.values) {
      if (l.tag == tag) return l;
    }
    return GlobeIdLocale.enUS;
  }
}

/// Canonical GlobeID brand strings, translated for every locale.
///
/// Mono-cap eyebrows + watermark strings stay LTR Latin so the
/// monogram reads identically across locales — only body labels,
/// CTA captions, and chronicle entries flex.
class GlobeIdStrings {
  const GlobeIdStrings({
    required this.appName,
    required this.brandTagline,
    required this.continueAction,
    required this.scanAction,
    required this.payAction,
    required this.shareAction,
    required this.verifiedLabel,
    required this.issuedLabel,
    required this.clearedLabel,
    required this.signedByGlobeId,
    required this.manufacturedCredential,
    required this.localePickerTitle,
    required this.localePickerEyebrow,
    required this.localePickerCaption,
  });

  final String appName;
  final String brandTagline;
  final String continueAction;
  final String scanAction;
  final String payAction;
  final String shareAction;
  final String verifiedLabel;
  final String issuedLabel;
  final String clearedLabel;
  final String signedByGlobeId;
  final String manufacturedCredential;
  final String localePickerTitle;
  final String localePickerEyebrow;
  final String localePickerCaption;

  static const Map<GlobeIdLocale, GlobeIdStrings> _bundles = {
    GlobeIdLocale.enUS: GlobeIdStrings(
      appName: 'GlobeID',
      brandTagline: 'Manufactured credential',
      continueAction: 'Continue',
      scanAction: 'Scan',
      payAction: 'Pay',
      shareAction: 'Share',
      verifiedLabel: 'Verified',
      issuedLabel: 'Issued',
      clearedLabel: 'Cleared',
      signedByGlobeId: 'Signed by GlobeID',
      manufacturedCredential: 'Manufactured credential',
      localePickerTitle: 'Language',
      localePickerEyebrow: 'LOCALE · LADDER',
      localePickerCaption:
          'Brand chrome stays foil + mono-cap across every locale.',
    ),
    GlobeIdLocale.arSA: GlobeIdStrings(
      appName: 'GlobeID',
      brandTagline: 'وثيقة مُصنّعة',
      continueAction: 'متابعة',
      scanAction: 'مسح',
      payAction: 'ادفع',
      shareAction: 'مشاركة',
      verifiedLabel: 'موثّق',
      issuedLabel: 'مُصدر',
      clearedLabel: 'تمت المعالجة',
      signedByGlobeId: 'موقّع من GlobeID',
      manufacturedCredential: 'وثيقة مُصنّعة',
      localePickerTitle: 'اللغة',
      localePickerEyebrow: 'LOCALE · LADDER',
      localePickerCaption:
          'تبقى علامة GlobeID بلون الذهب والأحرف الكبيرة في كل اللغات.',
    ),
    GlobeIdLocale.zhCN: GlobeIdStrings(
      appName: 'GlobeID',
      brandTagline: '精制凭证',
      continueAction: '继续',
      scanAction: '扫描',
      payAction: '支付',
      shareAction: '分享',
      verifiedLabel: '已验证',
      issuedLabel: '已签发',
      clearedLabel: '已通关',
      signedByGlobeId: '由 GlobeID 签发',
      manufacturedCredential: '精制凭证',
      localePickerTitle: '语言',
      localePickerEyebrow: 'LOCALE · LADDER',
      localePickerCaption: 'GlobeID 标识保持金色单宽大写，跨语言不变。',
    ),
    GlobeIdLocale.esES: GlobeIdStrings(
      appName: 'GlobeID',
      brandTagline: 'Credencial fabricada',
      continueAction: 'Continuar',
      scanAction: 'Escanear',
      payAction: 'Pagar',
      shareAction: 'Compartir',
      verifiedLabel: 'Verificado',
      issuedLabel: 'Emitido',
      clearedLabel: 'Despachado',
      signedByGlobeId: 'Firmado por GlobeID',
      manufacturedCredential: 'Credencial fabricada',
      localePickerTitle: 'Idioma',
      localePickerEyebrow: 'LOCALE · LADDER',
      localePickerCaption:
          'El cromo de marca permanece en oro + mayúsculas mono en cada idioma.',
    ),
    GlobeIdLocale.jaJP: GlobeIdStrings(
      appName: 'GlobeID',
      brandTagline: '製造された資格',
      continueAction: '続ける',
      scanAction: 'スキャン',
      payAction: '支払う',
      shareAction: '共有',
      verifiedLabel: '認証済み',
      issuedLabel: '発行済み',
      clearedLabel: '通過済み',
      signedByGlobeId: 'GlobeID により署名',
      manufacturedCredential: '製造された資格',
      localePickerTitle: '言語',
      localePickerEyebrow: 'LOCALE · LADDER',
      localePickerCaption:
          'ブランドの金色とモノキャップは、どの言語でも同じです。',
    ),
  };

  static GlobeIdStrings of(GlobeIdLocale locale) =>
      _bundles[locale] ?? _bundles[GlobeIdLocale.enUS]!;
}

/// Inherited locale state. Wraps the entire app in
/// `GlobeIdLocaleScope` so any descendant can resolve the active
/// locale + strings + flip its layout direction.
class GlobeIdLocaleScope extends StatefulWidget {
  const GlobeIdLocaleScope({
    super.key,
    required this.initial,
    required this.child,
  });
  final GlobeIdLocale initial;
  final Widget child;

  static GlobeIdLocaleScopeState of(BuildContext context) {
    final state = context.findAncestorStateOfType<GlobeIdLocaleScopeState>();
    assert(state != null, 'No GlobeIdLocaleScope above this context');
    return state!;
  }

  static GlobeIdLocale localeOf(BuildContext context) {
    final inh = context.dependOnInheritedWidgetOfExactType<_GlobeIdLocaleInherited>();
    return inh?.locale ?? GlobeIdLocale.enUS;
  }

  static GlobeIdStrings stringsOf(BuildContext context) =>
      GlobeIdStrings.of(localeOf(context));

  @override
  State<GlobeIdLocaleScope> createState() => GlobeIdLocaleScopeState();
}

class GlobeIdLocaleScopeState extends State<GlobeIdLocaleScope> {
  late GlobeIdLocale _locale = widget.initial;

  GlobeIdLocale get locale => _locale;

  void setLocale(GlobeIdLocale next) {
    if (next == _locale) return;
    setState(() => _locale = next);
  }

  @override
  Widget build(BuildContext context) {
    return _GlobeIdLocaleInherited(
      locale: _locale,
      child: Directionality(
        textDirection: _locale.textDirection,
        child: widget.child,
      ),
    );
  }
}

class _GlobeIdLocaleInherited extends InheritedWidget {
  const _GlobeIdLocaleInherited({
    required this.locale,
    required super.child,
  });
  final GlobeIdLocale locale;

  @override
  bool updateShouldNotify(covariant _GlobeIdLocaleInherited oldWidget) =>
      oldWidget.locale != locale;
}
