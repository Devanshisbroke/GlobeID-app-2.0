/// Wallet types — mirror `shared/types/wallet.ts`.
class WalletBalance {
  WalletBalance({
    required this.currency,
    required this.symbol,
    required this.amount,
    required this.flag,
    required this.rate,
  });

  final String currency;
  final String symbol;
  final double amount;
  final String flag;
  final double rate;

  factory WalletBalance.fromJson(Map<String, dynamic> j) => WalletBalance(
        currency: j['currency'] as String,
        symbol: j['symbol'] as String,
        amount: (j['amount'] as num).toDouble(),
        flag: j['flag'] as String,
        rate: (j['rate'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'symbol': symbol,
        'amount': amount,
        'flag': flag,
        'rate': rate,
      };
}

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.type,
    required this.description,
    this.merchant,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    this.location,
    this.country,
    this.countryFlag,
    required this.icon,
    this.reference,
  });

  final String id;
  final String type; // payment | send | receive | convert | refund
  final String description;
  final String? merchant;
  final double amount;
  final String currency;
  final String date;
  final String category;
  final String? location;
  final String? country;
  final String? countryFlag;
  final String icon;
  final String? reference;

  factory WalletTransaction.fromJson(Map<String, dynamic> j) =>
      WalletTransaction(
        id: j['id'] as String,
        type: j['type'] as String,
        description: j['description'] as String,
        merchant: j['merchant'] as String?,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String,
        date: j['date'] as String,
        category: j['category'] as String,
        location: j['location'] as String?,
        country: j['country'] as String?,
        countryFlag: j['countryFlag'] as String?,
        icon: j['icon'] as String,
        reference: j['reference'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        if (merchant != null) 'merchant': merchant,
        'amount': amount,
        'currency': currency,
        'date': date,
        'category': category,
        if (location != null) 'location': location,
        if (country != null) 'country': country,
        if (countryFlag != null) 'countryFlag': countryFlag,
        'icon': icon,
        if (reference != null) 'reference': reference,
      };
}

class WalletState {
  WalletState({required this.defaultCurrency, this.activeCountry});
  final String defaultCurrency;
  final String? activeCountry;

  factory WalletState.fromJson(Map<String, dynamic> j) => WalletState(
        defaultCurrency: j['defaultCurrency'] as String,
        activeCountry: j['activeCountry'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'defaultCurrency': defaultCurrency,
        if (activeCountry != null) 'activeCountry': activeCountry,
      };
}

class WalletSnapshot {
  WalletSnapshot({
    required this.balances,
    required this.transactions,
    required this.state,
  });
  final List<WalletBalance> balances;
  final List<WalletTransaction> transactions;
  final WalletState state;

  factory WalletSnapshot.fromJson(Map<String, dynamic> j) => WalletSnapshot(
        balances: (j['balances'] as List)
            .map((e) => WalletBalance.fromJson(e as Map<String, dynamic>))
            .toList(),
        transactions: (j['transactions'] as List)
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        state: WalletState.fromJson(j['state'] as Map<String, dynamic>),
      );
}
