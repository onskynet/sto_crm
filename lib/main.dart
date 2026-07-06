import 'package:flutter/material.dart';

void main() {
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

// Модель заказа
class Order {
  String clientName;
  String phone;
  String car;
  String problem;
  String status;
  double price;

  Order({
    required this.clientName,
    required this.phone,
    required this.car,
    required this.problem,
    this.status = 'Новый',
    this.price = 0,
  });
}

// Главный экран
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Список заказов. Пока в памяти
  List<Order> orders = [
    Order(clientName: 'Иван Петров', phone: '+7 701 123 4567', car: 'Toyota Camry', problem: 'Замена масла', price: 8000),
    Order(clientName: 'Алия С.', phone: '+7 777 555 4433', car: 'BMW X5', problem: 'Диагностика ходовой', price: 15000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STO CRM'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: orders.isEmpty
         ? const Center(child: Text('Заказов пока нет'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(order.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${order.car} • ${order.problem}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${order.price.toInt()} ₸', style: const TextStyle(fontSize: 16)),
                        Text(order.status, style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                      ],
                    ),
                    onTap: () {
                      // Тут будет экран деталей
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Открываем заказ: ${order.clientName}')),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Переход на экран добавления
          final newOrder = await Navigator.push<Order>(
            context,
            MaterialPageRoute(builder: (context) => const AddOrderScreen()),
          );
          if (newOrder!= null) {
            setState(() {
              orders.add(newOrder);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Экран добавления заказа
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО клиента'),
                validator: (v) => v!.isEmpty? 'Заполни поле' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Телефон'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty? 'Заполни поле' : null,
              ),
              TextFormField(
                controller: _carController,
                decoration: const InputDecoration(labelText: 'Марка и модель авто'),
                validator: (v) => v!.isEmpty? 'Заполни поле' : null,
              ),
              TextFormField(
                controller: _problemController,
                decoration: const InputDecoration(labelText: 'Проблема'),
                maxLines: 3,
                validator: (v) => v!.isEmpty? 'Заполни поле' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Сумма, ₸'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final order = Order(
                      clientName: _nameController.text,
                      phone: _phoneController.text,
                      car: _carController.text,
                      problem: _problemController.text,
                      price: double.tryParse(_priceController.text)?? 0,
                    );
                    Navigator.pop(context, order);
                  }
                },
                child: const Text('Сохранить заказ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
