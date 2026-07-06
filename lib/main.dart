import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const StoApp());
}

class StoApp extends StatelessWidget {
  const StoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STO CRM',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const OrdersScreen(),
    );
  }
}

class Order {
  final String id, name, phone, car, problem, status;
  final int price;
  final Timestamp createdAt;
  Order({required this.id, required this.name, required this.phone, required this.car,
         required this.problem, required this.price, required this.status, required this.createdAt});
  factory Order.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id, name: d['name']?? '', phone: d['phone']?? '', car: d['car']?? '',
      problem: d['problem']?? '', price: d['price']?? 0, status: d['status']?? 'Новый',
      createdAt: d['createdAt']?? Timestamp.now(),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _search = '';
  String _filterStatus = 'Все';
  final _statuses = ['Все', 'Новый', 'В работе', 'Готов', 'Выдан'];

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true);
    if (_filterStatus!= 'Все') query = query.where('status', isEqualTo: _filterStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('STO CRM'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск: ФИО, телефон, машина',
                    prefixIcon: const Icon(Icons.search),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _search = val.toLowerCase()),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: _statuses.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: _filterStatus == s,
                    onSelected: (_) => setState(() => _filterStatus = s),
                  ),
                )).toList()),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var orders = snapshot.data!.docs.map((doc) => Order.fromDoc(doc)).toList();

          if (_search.isNotEmpty) {
            orders = orders.where((o) =>
              o.name.toLowerCase().contains(_search) ||
              o.phone.contains(_search) ||
              o.car.toLowerCase().contains(_search)
            ).toList();
          }

          final totalSum = orders.fold<int>(0, (sum, o) => sum + o.price);

          return Column(
            children: [
              if (orders.isNotEmpty) Container(
                width: double.infinity, padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: Text('Заказов: ${orders.length} • Сумма: $totalSum ₸',
                  style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
              Expanded(
                child: orders.isEmpty
                 ? const Center(child: Text('Заказов нет'))
                  : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, i) => _OrderTile(order: orders[i]),
                  ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddOrderScreen())),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'В работе': return Colors.orange;
      case 'Готов': return Colors.green;
      case 'Выдан': return Colors.grey;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(order.id),
      background: Container(color: Colors.red, alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить заказ?'),
          content: Text('Заказ ${order.name} будет удален навсегда'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
          ],
        ),
      ),
      onDismissed: (_) => FirebaseFirestore.instance.collection('orders').doc(order.id).delete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          title: Text(order.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${order.car} • ${order.problem}'),
            Text(order.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt.toDate()),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${order.price} ₸', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _getStatusColor(order.status), borderRadius: BorderRadius.circular(12)),
              child: Text(order.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ]),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditOrderScreen(order: order))),
        ),
      ),
    );
  }
}

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});
  @override State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _name = TextEditingController(), _phone = TextEditingController();
  final _car = TextEditingController(), _problem = TextEditingController(), _price = TextEditingController();

  void _save() {
    if (_name.text.isEmpty) return;
    FirebaseFirestore.instance.collection('orders').add({
      'name': _name.text, 'phone': _phone.text, 'car': _car.text, 'problem': _problem.text,
      'price': int.tryParse(_price.text)?? 0, 'status': 'Новый', 'createdAt': Timestamp.now(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый заказ')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'ФИО клиента')),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Телефон'), keyboardType: TextInputType.phone),
        TextField(controller: _car, decoration: const InputDecoration(labelText: 'Машина')),
        TextField(controller: _problem, decoration: const InputDecoration(labelText: 'Проблема'), maxLines: 2),
        TextField(controller: _price, decoration: const InputDecoration(labelText: 'Сумма'), keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _save, child: const Text('Сохранить заказ')),
      ]),
    );
  }
}

class EditOrderScreen extends StatefulWidget {
  final Order order;
  const EditOrderScreen({super.key, required this.order});
  @override State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late final TextEditingController _name, _phone, _car, _problem, _price;
  late String _status;
  final statuses = ['Новый', 'В работе', 'Готов', 'Выдан'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.order.name);
    _phone = TextEditingController(text: widget.order.phone);
    _car = TextEditingController(text: widget.order.car);
    _problem = TextEditingController(text: widget.order.problem);
    _price = TextEditingController(text: widget.order.price.toString());
    _status = widget.order.status;
  }

  void _update() {
    FirebaseFirestore.instance.collection('orders').doc(widget.order.id).update({
      'name': _name.text, 'phone': _phone.text, 'car': _car.text, 'problem': _problem.text,
      'price': int.tryParse(_price.text)?? 0, 'status': _status,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать заказ')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'ФИО клиента')),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Телефон'), keyboardType: TextInputType.phone),
        TextField(controller: _car, decoration: const InputDecoration(labelText: 'Машина')),
        TextField(controller: _problem, decoration: const InputDecoration(labelText: 'Проблема'), maxLines: 2),
        TextField(controller: _price, decoration: const InputDecoration(labelText: 'Сумма'), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Статус'),
          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) => setState(() => _status = val!),
        ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _update, child: const Text('Сохранить изменения')),
      ]),
    );
  }
}
