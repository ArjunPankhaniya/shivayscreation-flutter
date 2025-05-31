import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Ensure AppOrder is imported from your order_provider.dart
import '../providers/order_provider.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onRefresh; // This is for external refresh, e.g., from HomeScreen

  const MyOrdersScreen({super.key, this.onRefresh});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch orders when the screen is initialized, but do it *after* the first frame.
    // This ensures that initState completes and the initial build phase is over
    // before notifyListeners() might be called by the provider.
    Future.microtask(() {
      // Check if mounted in case the widget is disposed before microtask runs
      if (mounted) {
        // We set listen: false here because initState should not cause
        // this widget itself to rebuild based on this initial call.
        // The Consumer/Provider.of in the build method will handle updates.
        Provider.of<OrdersProvider>(context, listen: false)
            .fetchOrders(); // No need for force: true unless specifically desired on init
        // widget.onRefresh?.call(); // Usually not needed here, onRefresh is for user pull
      }
    });
  }

  Future<void> _fetchOrdersData({bool force = false}) async {
    if (mounted) {
      await Provider.of<OrdersProvider>(context, listen: false)
          .fetchOrders(forceRefresh: force);
      // widget.onRefresh?.call(); // This is for external refresh, no need to call it from internal fetch logic
    }
  }

  // Updated to take DateTime directly
  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM, yyyy').format(date.toLocal());
    } catch (e) {
      // Fallback if date is somehow still problematic, though AppOrder should ensure valid DateTime
      return date.toIso8601String().substring(0, 10);
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    status = status.toLowerCase();
    if (status.contains('delivered') || status.contains('completed')) {
      return Colors.green.shade700;
    } else if (status.contains('shipped') || status.contains('processing')) {
      return Colors.orange.shade700;
    } else if (status.contains('cancelled') || status.contains('failed')) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurface.withOpacity(0.7); // Default/Pending
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use Consumer to react to provider changes for loading/error states and order list
    return Consumer<OrdersProvider>(
      builder: (ctx, ordersProvider, child) {
        Widget bodyContent;

        if (ordersProvider.isLoading && ordersProvider.orders.isEmpty) {
          bodyContent = const Center(child: CircularProgressIndicator());
        } else if (ordersProvider.hasError && ordersProvider.orders.isEmpty) {
          bodyContent = Center( /* ... Your error UI ... */ );
        } else if (ordersProvider.orders.isEmpty && !ordersProvider.isLoading) {
          bodyContent = Center( /* ... Your empty orders UI ... */ );
        } else {
          bodyContent = ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            itemCount: ordersProvider.orders.length,
            itemBuilder: (context, index) {
              // Corrected: order is now AppOrder
              final AppOrder order = ordersProvider.orders[index];

              return OrderCard(
                // Access properties using dot notation
                orderId: order.orderId, // or order.id if you prefer doc ID
                status: order.status,
                totalAmount: order.totalAmount.toStringAsFixed(2), // Convert double to formatted string
                orderDate: _formatDate(order.orderDate), // Pass DateTime object
                paymentmethod: order.paymentMethod.toString(),
                products: order.products, // This is List<Map<String, dynamic>>
                statusColor: _getStatusColor(order.status, theme),
                onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
                  );

                  if (mounted) Navigator.pop(context); // Dismiss loading indicator

                  // Use the toMap() method from AppOrder

                  // Ensure OrderDetailsScreen can handle the 'timestamp' field from toMap()
                  // or convert it to a string if needed:
                  // orderDataForDetails['orderDateString'] = _formatDate(order.orderDate);
                  // DEBUG PRINT (Highly Recommended)
                  // print("--- MyOrdersScreen: Data being passed to OrderDetailsScreen ---");

                  // print("-------------------------------------------------------------");


                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(orderId: order.id),
                      ),
                    );
                  }
                },
              );
            },
          );
        }

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (bool didPop, dynamic result) async {
            if (didPop && mounted) {
              _fetchOrdersData(force: true); // Refresh on pop
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text("My Orders"),
              elevation: 1,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
            ),
            // backgroundColor: theme.colorScheme.background,
            body: RefreshIndicator(
              onRefresh: () => _fetchOrdersData(force: true), // Internal refresh
              child: bodyContent,
            ),
          ),
        );
      },
    );
  }
}

// OrderCard remains largely the same, but ensure it uses the data correctly
// For example, totalAmount is now a String, products is List<Map<String, dynamic>>
// Ensure productData['imageUrl'] is correctly accessed within OrderCard's product mapping.
class OrderCard extends StatelessWidget {
  final String orderId;
  final String status;
  final String totalAmount; // Expecting a formatted string
  final String orderDate;
  final String paymentmethod;// Expecting a formatted string
  // This was List<dynamic>, ensure it's List<Map<String, dynamic>>
  // if AppOrder.products is List<Map<String, dynamic>>
  final List<Map<String, dynamic>> products;
  final Color statusColor;
  final VoidCallback onTap;

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    required this.paymentmethod,
    required this.products,
    required this.statusColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const int maxPreviewImages = 3;
    final previewProducts = products.take(maxPreviewImages).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "Order #$orderId",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12.0),
              if (previewProducts.isNotEmpty) ...[
                SizedBox(
                  height: 60,
                  child: Row(
                    children: previewProducts.map((productData) {
                      // productData is already Map<String, dynamic> from AppOrder.products
                      String? imageUrl = productData['imageUrl']?.toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                            imageUrl,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400])),
                          )
                              : Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.0)), child: Icon(Icons.image_not_supported, color: Colors.grey[400])),
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
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 12.0),
              ],
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Amount", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text(
                    "₹$totalAmount", // totalAmount is already a formatted string
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text("Tap to view details", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
              )
            ],
          ),
        ),
      ),
    );
  }
}