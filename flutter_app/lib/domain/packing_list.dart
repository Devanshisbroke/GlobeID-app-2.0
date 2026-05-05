/// Dart port of `src/lib/packingList.ts`. Generates a deterministic
/// packing checklist from destination + duration + season.
class PackingItem {
  const PackingItem(this.id, this.label, this.category,
      [this.essential = false]);
  final String id;
  final String label;
  final String category;
  final bool essential;
}

class PackingList {
  static List<PackingItem> generate({
    required String destinationCountry,
    required int days,
    required DateTime departure,
    bool isBeach = false,
    bool isCold = false,
    bool isBusiness = false,
  }) {
    final items = <PackingItem>[
      const PackingItem('p1', 'Passport', 'docs', true),
      const PackingItem('p2', 'Boarding pass', 'docs', true),
      const PackingItem('p3', 'Phone + charger', 'tech', true),
      const PackingItem('p4', 'Wallet + cards', 'docs', true),
      PackingItem('c1', '${days * 1} shirts', 'clothes'),
      PackingItem('c2', '${(days / 2).ceil()} pants', 'clothes'),
      PackingItem('c3', '${days + 1} underwear', 'clothes'),
      const PackingItem('t1', 'Toothbrush + toothpaste', 'toiletries'),
      const PackingItem('t2', 'Deodorant', 'toiletries'),
      const PackingItem('t3', 'Travel-size shampoo', 'toiletries'),
    ];

    if (isBeach) {
      items.addAll(const [
        PackingItem('b1', 'Swimsuit', 'clothes'),
        PackingItem('b2', 'Sunscreen SPF 50+', 'toiletries'),
        PackingItem('b3', 'Sandals', 'clothes'),
        PackingItem('b4', 'Beach towel', 'gear'),
      ]);
    }
    if (isCold) {
      items.addAll(const [
        PackingItem('w1', 'Down jacket', 'clothes'),
        PackingItem('w2', 'Thermal layers', 'clothes'),
        PackingItem('w3', 'Gloves + beanie', 'clothes'),
      ]);
    }
    if (isBusiness) {
      items.addAll(const [
        PackingItem('z1', 'Suit / blazer', 'clothes'),
        PackingItem('z2', 'Dress shoes', 'clothes'),
        PackingItem('z3', 'Laptop + power adapter', 'tech', true),
      ]);
    }

    return items;
  }
}
