import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'data/app_database.dart';

final localeProvider = StateProvider<bool>((ref) => true);
final refreshProvider = StateProvider<int>((ref) => 0);

void main() => runApp(const ProviderScope(child: BharatDairyApp()));

String money(num n) => '₹${n.toStringAsFixed(2)}';
String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class BharatDairyApp extends ConsumerWidget {
  const BharatDairyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hindi = ref.watch(localeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bharat Dairy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b45)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f8f5),
      ),
      home: HomeScreen(hindi: hindi),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  final bool hindi;
  const HomeScreen({super.key, required this.hindi});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int tab = 0;
  String t(String hi, String en) => widget.hindi ? hi : en;

  @override
  Widget build(BuildContext context) {
    ref.watch(refreshProvider);
    final pages = <Widget>[
      Dashboard(hindi: widget.hindi),
      RegisterScreen(hindi: widget.hindi),
      RateScreen(hindi: widget.hindi),
      MonthlyScreen(hindi: widget.hindi),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('भारत डेयरी | Bharat Dairy'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(localeProvider.notifier).state = !widget.hindi,
            child: Text(widget.hindi ? 'EN' : 'हिंदी'),
          ),
        ],
      ),
      body: pages[tab],
      floatingActionButton: tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => showEntry(context, widget.hindi, ref),
              icon: const Icon(Icons.add),
              label: Text(t('नई एंट्री', 'New Entry')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              label: t('होम', 'Home')),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long),
              label: t('रजिस्टर', 'Register')),
          NavigationDestination(
              icon: const Icon(Icons.tune),
              label: t('रेट सेटिंग', 'Rates')),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month),
              label: t('मासिक बिल', 'Monthly')),
        ],
      ),
    );
  }
}

class Dashboard extends ConsumerWidget {
  final bool hindi;
  const Dashboard({super.key, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateKey(DateTime.now());
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    return FutureBuilder<List<Map<String, Object?>>>(
      future: AppDatabase.instance.entries(month: month),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? <Map<String, Object?>>[];
        final todayRows = rows.where((r) => r['date'] == today).toList();
        double sum(String kind, String field) => todayRows
            .where((r) => r['kind'] == kind)
            .fold<double>(
                0, (a, r) => a + ((r[field] as num?)?.toDouble() ?? 0));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(hindi ? 'आज का कामकाज' : 'Today at a glance',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _metric(context, hindi ? 'आज का दूध संकलन' : 'Milk collected',
                  '${sum('collection', 'quantity').toStringAsFixed(2)} L',
                  Icons.water_drop),
              _metric(context, hindi ? 'आज की दूध बिक्री' : 'Milk sold',
                  '${sum('sale', 'quantity').toStringAsFixed(2)} L',
                  Icons.shopping_cart),
              _metric(context, hindi ? 'किसान भुगतान' : 'Farmer payable',
                  money(sum('collection', 'amount')), Icons.payments),
              _metric(context, hindi ? 'बिक्री राशि' : 'Sales amount',
                  money(sum('sale', 'amount')), Icons.currency_rupee),
            ]),
            const SizedBox(height: 20),
            Text(hindi ? 'जल्दी एंट्री करें' : 'Quick actions'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      showEntry(context, hindi, ref, kind: 'collection'),
                  icon: const Icon(Icons.add),
                  label: Text(hindi ? 'दूध जमा' : 'Collection'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showEntry(context, hindi, ref, kind: 'sale'),
                  icon: const Icon(Icons.sell),
                  label: Text(hindi ? 'दूध बिक्री' : 'Milk sale'),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text(hindi ? 'हाल की एंट्री' : 'Recent entries'),
            ...todayRows.take(8).map((r) => ListTile(
                  leading: Icon(
                      r['kind'] == 'sale' ? Icons.sell : Icons.water_drop),
                  title: Text('${r['farmer']} • ${r['quantity']} L'),
                  subtitle:
                      Text('${r['shift'] ?? ''} ${r['animal']} • ${r['date']}'),
                  trailing: Text(money((r['amount'] as num?) ?? 0)),
                )),
          ],
        );
      },
    );
  }
}

Widget _metric(
    BuildContext c, String title, String value, IconData icon) {
  return SizedBox(
    width: MediaQuery.of(c).size.width / 2 - 22,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(c).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(c).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(c)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );
}

class RegisterScreen extends ConsumerWidget {
  final bool hindi;
  const RegisterScreen({super.key, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: AppDatabase.instance.entries(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? <Map<String, Object?>>[];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(hindi
                ? 'दूध संकलन और बिक्री रजिस्टर'
                : 'Milk collection & sales register'),
            ...rows.map((r) => Card(
                  child: ListTile(
                    leading: Icon(
                        r['kind'] == 'sale' ? Icons.sell : Icons.water_drop),
                    title: Text('${r['farmer']} • ${r['quantity']} L'),
                    subtitle: Text(
                        '${r['kind'] == 'sale' ? (hindi ? 'बिक्री' : 'Sale') : (hindi ? 'संकलन' : 'Collection')} | ${r['shift'] ?? ''} | ${r['date']} | ${r['animal']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(money((r['amount'] as num?) ?? 0)),
                        Text('${r['fat']}F / ${r['snf']}S',
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                    onLongPress: () async {
                      await AppDatabase.instance.deleteEntry(r['id'] as int);
                      ref.read(refreshProvider.notifier).state++;
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              hindi ? 'एंट्री हटाई गई' : 'Entry deleted')));
                    },
                  ),
                )),
          ],
        );
      },
    );
  }
}

Future<void> showEntry(BuildContext context, bool hindi, WidgetRef ref,
    {String kind = 'collection'}) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final qty = TextEditingController();
  final fat = TextEditingController(text: '4.0');
  final snf = TextEditingController(text: '8.5');
  final rate = TextEditingController();
  final deduction = TextEditingController(text: '0');
  String shift = 'morning';
  String animal = 'cow';
  DateTime date = DateTime.now();
  final sale = kind == 'sale';

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(hindi
              ? (sale ? 'दूध बिक्री एंट्री' : 'दूध संकलन एंट्री')
              : (sale ? 'Milk sale entry' : 'Milk collection entry')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  decoration: InputDecoration(
                      labelText: hindi
                          ? (sale ? 'खरीदार का नाम' : 'किसान का नाम')
                          : (sale ? 'Buyer name' : 'Farmer name'))),
              TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: hindi ? 'मोबाइल नंबर' : 'Phone number')),
              DropdownButtonFormField<String>(
                initialValue: animal,
                decoration: InputDecoration(
                    labelText: hindi ? 'दूध का प्रकार' : 'Milk type'),
                items: [
                  DropdownMenuItem(
                      value: 'cow', child: Text(hindi ? 'गाय' : 'Cow')),
                  DropdownMenuItem(
                      value: 'buffalo',
                      child: Text(hindi ? 'भैंस' : 'Buffalo')),
                  DropdownMenuItem(
                      value: 'mixed', child: Text(hindi ? 'मिक्स' : 'Mixed')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => animal = v);
                },
              ),
              if (!sale)
                DropdownButtonFormField<String>(
                  initialValue: shift,
                  decoration: InputDecoration(
                      labelText: hindi ? 'शिफ्ट' : 'Shift'),
                  items: [
                    DropdownMenuItem(
                        value: 'morning',
                        child: Text(hindi ? 'सुबह' : 'Morning')),
                    DropdownMenuItem(
                        value: 'evening',
                        child: Text(hindi ? 'शाम' : 'Evening')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => shift = v);
                  },
                ),
              TextField(
                  controller: qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText:
                          hindi ? 'मात्रा (लीटर)' : 'Quantity (litres)')),
              TextField(
                  controller: fat,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Fat %')),
              TextField(
                  controller: snf,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'SNF %')),
              TextField(
                  controller: rate,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: hindi ? 'रेट ₹/लीटर' : 'Rate ₹/litre')),
              if (!sale)
                TextField(
                    controller: deduction,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: hindi ? 'कटौती ₹' : 'Deductions ₹')),
              TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: dialogContext,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setDialogState(() => date = d);
                },
                icon: const Icon(Icons.date_range),
                label: Text(DateFormat('dd-MM-yyyy').format(date)),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(hindi ? 'रद्द' : 'Cancel')),
            FilledButton(
              onPressed: () async {
                final q = double.tryParse(qty.text) ?? 0;
                final r = double.tryParse(rate.text) ?? 0;
                final ded = double.tryParse(deduction.text) ?? 0;
                if (name.text.trim().isEmpty || q <= 0 || r <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                      content: Text(hindi
                          ? 'नाम, मात्रा और रेट सही भरें'
                          : 'Enter a name, positive quantity and rate')));
                  return;
                }
                final amount = q * r - (sale ? 0 : ded);
                if (amount < 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                      content: Text(hindi
                          ? 'कटौती राशि कुल रकम से अधिक है'
                          : 'Deductions exceed gross amount')));
                  return;
                }
                await AppDatabase.instance.addEntry({
                  'kind': sale ? 'sale' : 'collection',
                  'farmer': name.text.trim(),
                  'phone': phone.text.trim(),
                  'animal': animal,
                  'shift': sale ? null : shift,
                  'quantity': q,
                  'fat': double.tryParse(fat.text) ?? 0,
                  'snf': double.tryParse(snf.text) ?? 0,
                  'rate': r,
                  'amount': amount,
                  'deductions': ded,
                  'date': dateKey(date),
                  'created_at': DateTime.now().toIso8601String(),
                });
                ref.read(refreshProvider.notifier).state++;
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: Text(hindi ? 'सेव करें' : 'Save'),
            ),
          ],
        ),
      ),
    );
  } finally {
    name.dispose();
    phone.dispose();
    qty.dispose();
    fat.dispose();
    snf.dispose();
    rate.dispose();
    deduction.dispose();
  }
}

class RateScreen extends StatefulWidget {
  final bool hindi;
  const RateScreen({super.key, required this.hindi});
  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  final cow = TextEditingController();
  final buffalo = TextEditingController();
  final fatFactor = TextEditingController();
  final snfFactor = TextEditingController();
  bool formula = false;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final c = await AppDatabase.instance.getSetting('fixed_rate_cow');
    final b = await AppDatabase.instance.getSetting('fixed_rate_buffalo');
    final f = await AppDatabase.instance.getSetting('fat_factor');
    final s = await AppDatabase.instance.getSetting('snf_factor');
    if (!mounted) return;
    setState(() {
      cow.text = c?['value']?.toString() ?? '0';
      buffalo.text = b?['value']?.toString() ?? '0';
      fatFactor.text = f?['value']?.toString() ?? '0';
      snfFactor.text = s?['value']?.toString() ?? '0';
      loaded = true;
    });
  }

  @override
  void dispose() {
    cow.dispose();
    buffalo.dispose();
    fatFactor.dispose();
    snfFactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hi = widget.hindi;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(hi ? 'रेट सेटिंग' : 'Rate settings',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (!loaded) const LinearProgressIndicator(),
      TextField(
          controller: cow,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: hi ? 'गाय का फिक्स रेट ₹/लीटर' : 'Cow fixed rate ₹/L')),
      TextField(
          controller: buffalo,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText:
                  hi ? 'भैंस का फिक्स रेट ₹/लीटर' : 'Buffalo fixed rate ₹/L')),
      SwitchListTile(
          value: formula,
          onChanged: (v) => setState(() => formula = v),
          title: Text(hi ? 'Fat + SNF फॉर्मूला' : 'Fat + SNF formula')),
      if (formula) ...[
        TextField(
            controller: fatFactor,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fat factor')),
        TextField(
            controller: snfFactor,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'SNF factor')),
      ],
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: () async {
          await AppDatabase.instance
              .setSetting('fixed_rate_cow', cow.text);
          await AppDatabase.instance
              .setSetting('fixed_rate_buffalo', buffalo.text);
          await AppDatabase.instance.setSetting('fat_factor', fatFactor.text);
          await AppDatabase.instance.setSetting('snf_factor', snfFactor.text);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(hi ? 'रेट सेव हो गए' : 'Rates saved')));
        },
        icon: const Icon(Icons.save),
        label: Text(hi ? 'रेट सेव करें' : 'Save rates'),
      ),
      const SizedBox(height: 10),
      Text(hi
          ? 'मिक्स दूध के लिए एंट्री के समय लागू रेट भरें।'
          : 'For mixed milk, enter the agreed rate in each entry.'),
    ]);
  }
}

class MonthlyScreen extends StatefulWidget {
  final bool hindi;
  const MonthlyScreen({super.key, required this.hindi});
  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  DateTime month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final hi = widget.hindi;
    final monthKey = DateFormat('yyyy-MM').format(month);
    return FutureBuilder<List<Map<String, Object?>>>(
      future: AppDatabase.instance.entries(month: monthKey),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? <Map<String, Object?>>[];
        double total(String kind, String field) => rows
            .where((r) => r['kind'] == kind)
            .fold<double>(
                0, (a, r) => a + ((r[field] as num?)?.toDouble() ?? 0));
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text(hi ? 'मासिक हिसाब' : 'Monthly statement',
              style: Theme.of(context).textTheme.titleLarge),
          ListTile(
            title: Text(DateFormat('MMMM yyyy').format(month)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: month,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (d != null) setState(() => month = d);
              },
            ),
          ),
          _summary(hi ? 'कुल दूध संकलन' : 'Total collected',
              '${total('collection', 'quantity').toStringAsFixed(2)} L'),
          _summary(hi ? 'कुल दूध बिक्री' : 'Total sold',
              '${total('sale', 'quantity').toStringAsFixed(2)} L'),
          _summary(hi ? 'किसान भुगतान' : 'Farmer payable',
              money(total('collection', 'amount'))),
          _summary(hi ? 'बिक्री रकम' : 'Sales revenue',
              money(total('sale', 'amount'))),
          _summary(hi ? 'कुल रिकॉर्ड' : 'Total records', '${rows.length}'),
          const SizedBox(height: 12),
          ...rows.map((r) => ListTile(
                title: Text('${r['farmer']} — ${r['quantity']} L'),
                subtitle: Text(
                    '${r['date']} • ${r['kind']} • ${r['animal']}'),
                trailing: Text(money((r['amount'] as num?) ?? 0)),
              )),
        ]);
      },
    );
  }
}

Widget _summary(String title, String value) => Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
