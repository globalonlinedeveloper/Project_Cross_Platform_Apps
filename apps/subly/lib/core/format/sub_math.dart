import '../../data/models/subscription.dart';

class CategoryTotal {
  const CategoryTotal(this.name, this.value);
  final String name;
  final double value;
}

/// Pure derivations shared by Home / Insights / Budget / Calendar.
class SubMath {
  SubMath._();

  static double totalMonthly(List<Subscription> s) =>
      s.fold(0.0, (double a, Subscription x) => a + x.monthlyPrice);

  static List<CategoryTotal> categoryTotals(List<Subscription> s) {
    final Map<String, double> m = <String, double>{};
    for (final Subscription x in s) {
      m[x.category] = (m[x.category] ?? 0) + x.monthlyPrice;
    }
    final List<CategoryTotal> list = m.entries
        .map((MapEntry<String, double> e) => CategoryTotal(e.key, e.value))
        .toList();
    list.sort((CategoryTotal a, CategoryTotal b) => b.value.compareTo(a.value));
    return list;
  }

  static List<Subscription> byMonthlyDesc(List<Subscription> s) {
    final List<Subscription> l = List<Subscription>.of(s);
    l.sort((Subscription a, Subscription b) =>
        b.monthlyPrice.compareTo(a.monthlyPrice));
    return l;
  }

  static List<Subscription> upcoming(List<Subscription> s, DateTime now,
      {int take = 4}) {
    final List<Subscription> l = List<Subscription>.of(s);
    l.sort((Subscription a, Subscription b) =>
        a.daysUntil(now).compareTo(b.daysUntil(now)));
    return l.take(take).toList();
  }

  static List<Subscription> unused(List<Subscription> s) =>
      s.where((Subscription x) => x.unused).toList();

  static double savings(List<Subscription> s) =>
      unused(s).fold(0.0, (double a, Subscription x) => a + x.monthlyPrice);

  static double dueWithin(List<Subscription> s, DateTime now, int days) =>
      s.where((Subscription x) {
        final int d = x.daysUntil(now);
        return d >= 0 && d <= days;
      }).fold(0.0, (double a, Subscription x) => a + x.monthlyPrice);
}
