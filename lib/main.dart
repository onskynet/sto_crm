import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBqxvfm1-DADjbmH8FoCkO2XqUuxwI2FKk',
      appId: '1:628737621368:android:e3be6ca9a981b75e4a9c8d',
      messagingSenderId: '628737621368',
      projectId: 'checkservicemerke',
      storageBucket: 'checkservicemerke.firebasestorage.app',
    ),
  );
  runApp(const STOCrmApp());
}

class STOCrmApp extends StatelessWidget {
  const STOCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STO CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Order {
  String id;
  String clientName;
  String phone;
  String car;
  String problem;
  String status;
  double price;

  Order({
    this.id = '',
    required this.clientName,
    required this.phone,
    required this.car,
    required this.problem,
    this.status = 'Новый',
    this.price = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'phone': phone,
      'car': car,
      'problem': problem,
      'status': status,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STO CRM'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Заказов пока нет'));
          }

          final orders = snapshot.data!.docs;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['clientName']?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['car']?? ''} • ${data['problem']?? ''}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(data['price']?? 0).toInt()} ₸', style: const TextStyle(fontSize: 16)),
                      Text(data['status']?? 'Новый', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddOrderScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carController = TextEditingController();
  final _problemController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final order = Order(
        clientName: _nameController.text,
        phone: _phoneController.text,
        car: _carController.text,
        problem: _problemController.text,
        price: double.tryParse(_priceController.text)?? 0,
      );

      await FirebaseFirestore.instance.collection('orders').add(order.toMap());

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый заказ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'ФИО клиента'), validator: (v) => v!.isEmpty? 'Заполни поле' : null),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Телефон'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty? 'Заполни поле' : null),
              TextFormField(controller: _carController, decoration: const InputDecoration(labelText: 'Марка и модель авто'), validator: (v) => v!.isEmpty? 'Заполни поле' : null),
              TextFormField(controller: _problemController, decoration: const InputDecoration(labelText: 'Проблема'), maxLines: 3, validator: (v) => v!.isEmpty? 'Заполни поле' : null),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Сумма, ₸'), keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading? null : _saveOrder,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isLoading? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Сохранить заказ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
