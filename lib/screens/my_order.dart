import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart'; // Assuming this path is correct

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onRefresh; // This is not used in the current build method
  const MyOrdersScreen({super.key, this.onRefresh});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);

    return PopScope(
      canPop: true, // Set to false if you want to conditionally prevent popping
      // Use the signature your IDE prefers and what's in your provided context
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          // If the pop actually happened. The 'result' parameter contains
          // the value that might have been passed to Navigator.pop(context, result)
          // if this screen was popped with a result. You are not using it here, which is fine.

          // Ensure context is still valid if the operation is async and potentially long,
          // though fetchOrders might be quick.
          if (mounted) {
            await Provider.of<OrdersProvider>(context, listen: false).fetchOrders(context);
          }
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            // Ensure context is valid if the operation is async
            if (mounted) {
              await Provider.of<OrdersProvider>(context, listen: false).fetchOrders(context);
            }
          },
          child: ordersProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ordersProvider.orders.isEmpty
              ? const Center(
            child: Text("No orders found.", style: TextStyle(fontSize: 18)),
          )
              : ListView.builder(
            itemCount: ordersProvider.orders.length,
            itemBuilder: (context, index) {
              var order = ordersProvider.orders[index];
              // It's safer to provide default values or handle potential nulls
              String orderId = order['orderId']?.toString() ?? 'N/A';
              String status = order['status']?.toString() ?? 'Pending';
              String totalAmount = order['totalAmount']?.toString() ?? '0';
              String orderDate = order['orderDate'] != null
                  ? order['orderDate'].toString().split(' ')[0]
                  : 'Unknown Date';
              List<dynamic> products = order['products'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  title: Text(
                    "Order ID: $orderId",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: $status"),
                      Text("Total: ₹$totalAmount"),
                      Text("Date: $orderDate"),
                    ],
                  ),
                  children: List.generate(products.length, (productIndex) {
                    var product = products[productIndex] as Map<String, dynamic>? ?? {};
                    String productName = product['name']?.toString() ?? 'Unnamed Product';
                    String productPrice = product['price']?.toString() ?? 'N/A';
                    String? imageUrl = product['imageUrl']?.toString();

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 60,
                              height: 60,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              width: 60,
                              height: 60,
                              child: Icon(Icons.broken_image, size: 40),
                            );
                          },
                        )
                            : const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
                      title: Text(productName),
                      subtitle: Text("Price: ₹$productPrice"),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}