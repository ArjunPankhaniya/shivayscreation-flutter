import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const MyOrdersScreen({Key? key, this.onRefresh}) : super(key: key);

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders(); // Orders fetch karne ke liye function call
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = fetchOrdersWithProducts();
    });
  }

  Future<List<Map<String, dynamic>>> fetchOrdersWithProducts() async {
    final User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> ordersWithProducts = [];

      for (var orderDoc in orderSnapshot.docs) {
        var orderData = orderDoc.data() as Map<String, dynamic>;
        if (!orderData.containsKey('products') || orderData['products'] == null) continue;

        List<dynamic> products = orderData['products'];
        ordersWithProducts.add({
          'orderId': orderDoc.id,
          'totalAmount': orderData['totalAmount'] ?? 0,
          'status': orderData['status'] ?? 'Pending',
          'orderDate': orderData['timestamp'] != null
              ? (orderData['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'products': products,
        });
      }

      return ordersWithProducts;
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _refreshOrders(); // Jab user back kare tab refresh ho
        return true;
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text("My Orders"),
        //   centerTitle: true,
        //   backgroundColor: Colors.lightBlue[800],
        // ),
        body: RefreshIndicator(
          onRefresh: () async {
            _refreshOrders(); // ✅ Refresh pe orders reload honge
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("No orders found.", style: TextStyle(fontSize: 18)),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var order = snapshot.data![index];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        "Order ID: ${order['orderId']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Status: ${order['status']}"),
                          Text("Total: ₹${order['totalAmount']}"),
                          Text("Date: ${order['orderDate'].toString().split(' ')[0]}"),
                        ],
                      ),
                      children: List.generate(order['products'].length, (productIndex) {
                        var product = order['products'][productIndex];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['imageUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(product['name']),
                          subtitle: Text("Price: ₹${product['price']}"),
                        );
                      }),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
