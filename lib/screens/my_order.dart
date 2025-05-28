import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import 'order_details_screen.dart'; // Assuming this path is correct

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const MyOrdersScreen({super.key, this.onRefresh});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // Helper to format date, if your date is a String, parse it first
  // If it's already a DateTime object from your provider, you can use it directly
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown Date';
    try {
      // Assuming dateString is in a format that DateTime.parse can handle
      // e.g., "YYYY-MM-DD HH:MM:SS" or "YYYY-MM-DD"
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM, yyyy').format(dateTime); // e.g., 23 Jul, 2024
    } catch (e) {
      return dateString; // Fallback to original string if parsing fails
    }
  }

  // Helper to get status color
  Color _getStatusColor(String status, ThemeData theme) {
    status = status.toLowerCase();
    if (status.contains('delivered') || status.contains('completed')) {
      return Colors.green.shade700;
    } else if (status.contains('shipped') || status.contains('processing')) {
      return Colors.orange.shade700;
    } else if (status.contains('cancelled') || status.contains('failed')) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurface.withOpacity(0.7); // Default
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          if (mounted) {
            await Provider.of<OrdersProvider>(context, listen: false)
                .fetchOrders(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Orders"),
          elevation: 1, // Subtle shadow for the app bar
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        backgroundColor: theme.colorScheme.background, // Match app background
        body: RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              await Provider.of<OrdersProvider>(context, listen: false)
                  .fetchOrders(context);
              widget.onRefresh?.call();
            }
          },
          child: ordersProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ordersProvider.orders.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    "No Orders Yet!",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "When you place an order, it will appear here.",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Pull down to refresh",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            itemCount: ordersProvider.orders.length,
            itemBuilder: (context, index) {
              var order = ordersProvider.orders[index];
              String orderId = order['orderId']?.toString() ?? 'N/A';
              String status = order['status']?.toString() ?? 'Pending';
              String totalAmount = order['totalAmount']?.toString() ?? '0.00';
              // Assuming order['orderDate'] is a String that needs parsing
              // If it's already a DateTime, you can skip DateTime.parse
              String formattedOrderDate = _formatDate(order['orderDate']?.toString());
              List<dynamic> products = order['products'] as List<dynamic>? ?? [];

              return OrderCard(
                orderId: orderId,
                status: status,
                totalAmount: totalAmount,
                orderDate: formattedOrderDate,
                products: products,
                statusColor: _getStatusColor(status, theme),
                // onTap: () {
                //   // Option 1: Navigate to a detailed order screen
                //   // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)));
                //
                //   // Option 2: Show a dialog with details (simpler for now)
                //   showDialog(
                //       context: context,
                //       builder: (ctx) => AlertDialog(
                //         title: Text("Order ID: $orderId"),
                //         content: SingleChildScrollView(
                //           child: Column(
                //             crossAxisAlignment:
                //             CrossAxisAlignment.start,
                //             mainAxisSize: MainAxisSize.min,
                //             children: [
                //               Text("Status: $status"),
                //               Text("Total: ₹$totalAmount"),
                //               Text("Date: $formattedOrderDate"),
                //               const SizedBox(height: 10),
                //               Text("Items:", style: theme.textTheme.titleSmall),
                //               ...products.map((prod) {
                //                 var product = prod as Map<String, dynamic>? ?? {};
                //                 return Text("- ${product['name'] ?? 'N/A'} (₹${product['price'] ?? 'N/A'})");
                //               }).toList(),
                //             ],
                //           ),
                //         ),
                //         actions: [
                //           TextButton(
                //               onPressed: () => Navigator.of(ctx).pop(),
                //               child: const Text("Close"))
                //         ],
                //       ));
                // },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(orderData: order), // Pass the full order map
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

class OrderCard extends StatelessWidget {
  final String orderId;
  final String status;
  final String totalAmount;
  final String orderDate;
  final List<dynamic> products;
  final Color statusColor;
  final VoidCallback onTap;

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    required this.products,
    required this.statusColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show a limited number of product images as previews
    const int maxPreviewImages = 3;
    final previewProducts = products.take(maxPreviewImages).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // Ensures content respects card shape
      child: InkWell(
        onTap: onTap, // Make the whole card tappable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #$orderId",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                "Placed on: $orderDate",
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12.0),
              if (previewProducts.isNotEmpty) ...[
                SizedBox(
                  height: 60, // Adjust height as needed
                  child: Row(
                    children: previewProducts.map((productData) {
                      var product = productData as Map<String, dynamic>? ?? {};
                      String? imageUrl = product['imageUrl']?.toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: Icon(Icons.broken_image, color: Colors.grey[400]),
                            ),
                          )
                              : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (products.length > maxPreviewImages)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "+${products.length - maxPreviewImages} more item(s)",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 12.0),
              ],
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Amount",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    "₹$totalAmount",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Tap to view details",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}