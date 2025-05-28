import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date and currency formatting

// You might need to import your product model if you have one,
// or just continue using Maps as in this example.

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsScreen({Key? key, required this.orderData}) : super(key: key);

  // Helper to format date
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM, yyyy - hh:mm a').format(dateTime); // e.g., 23 Jul, 2024 - 10:30 AM
    } catch (e) {
      return dateTimeString; // Fallback
    }
  }

  // Helper to format currency
  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹'); // Indian Rupee
    if (amount is String) {
      return numberFormat.format(double.tryParse(amount) ?? 0.0);
    } else if (amount is num) {
      return numberFormat.format(amount);
    }
    return 'N/A';
  }

  // Helper to get status color
  Color _getStatusColor(String? status, ThemeData theme) {
    status = status?.toLowerCase() ?? "";
    if (status.contains('delivered') || status.contains('completed')) {
      return Colors.green.shade700;
    } else if (status.contains('shipped') || status.contains('processing')) {
      return Colors.orange.shade700;
    } else if (status.contains('cancelled') || status.contains('failed')) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurface.withOpacity(0.7);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extracting data (with null safety and fallbacks)
    String orderId = orderData['orderId']?.toString() ?? 'N/A';
    String orderDate = _formatDateTime(orderData['orderDate']?.toString());
    String status = orderData['status']?.toString() ?? 'Pending';
    Color statusColor = _getStatusColor(status, theme);

    List<dynamic> products = orderData['products'] as List<dynamic>? ?? [];

    Map<String, dynamic> shippingAddress = orderData['shippingAddress'] as Map<String, dynamic>? ?? {};
    String shippingName = shippingAddress['name']?.toString() ?? 'N/A';
    String addressLine1 = shippingAddress['addressLine1']?.toString() ?? '';
    String addressLine2 = shippingAddress['addressLine2']?.toString() ?? '';
    String shippingCity = shippingAddress['city']?.toString() ?? '';
    String shippingState = shippingAddress['state']?.toString() ?? '';
    String shippingZip = shippingAddress['zipCode']?.toString() ?? '';
    String shippingPhone = shippingAddress['phone']?.toString() ?? 'N/A';
    String fullAddress = [addressLine1, addressLine2, shippingCity, shippingState, shippingZip]
        .where((s) => s.isNotEmpty)
        .join(', ');
    if (fullAddress.isEmpty) fullAddress = 'N/A';


    Map<String, dynamic> paymentDetails = orderData['paymentDetails'] as Map<String, dynamic>? ?? {};
    String paymentMethod = paymentDetails['method']?.toString() ?? 'N/A';
    String transactionId = paymentDetails['transactionId']?.toString() ?? 'N/A';
    String paymentStatus = paymentDetails['status']?.toString() ?? 'N/A';

    String subtotal = _formatCurrency(orderData['subtotal']);
    String shippingFee = _formatCurrency(orderData['shippingFee']);
    String discount = _formatCurrency(orderData['discount']);
    String totalAmount = _formatCurrency(orderData['totalAmount']);
    // String trackingNumber = orderData['trackingNumber']?.toString() ?? 'N/A';


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 4, // ✅ Adds subtle shadow
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(context, 'Shipping Information'),
            _buildShippingDetailsCard(context, shippingName, fullAddress, shippingPhone),
            const SizedBox(height: 16),

            _buildSectionTitle(context, 'Items Ordered (${products.length})'),
            _buildProductList(context, products),
            const SizedBox(height: 16),

            _buildSectionTitle(context, 'Payment Information'),
            _buildPaymentDetailsCard(context, paymentMethod, transactionId, paymentStatus, subtotal, shippingFee, discount, totalAmount),
            const SizedBox(height: 24),

            _buildOrderSummaryCard(context, orderId, orderDate, status, statusColor),
            const SizedBox(height: 16),
            // if (trackingNumber != 'N/A')
            //   Center(
            //     child: ElevatedButton.icon(
            //       icon: Icon(Icons.local_shipping_outlined),
            //       label: Text('Track Package'),
            //       onPressed: () {
            //         // Implement package tracking functionality
            //         // e.g., launch a URL with the trackingNumber
            //       },
            //       style: ElevatedButton.styleFrom(
            //         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, String orderId, String orderDate, String status, Color statusColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order ID:', style: theme.textTheme.bodyMedium),
                Text(orderId, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date Placed:', style: theme.textTheme.bodyMedium),
                Text(orderDate, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status:', style: theme.textTheme.bodyMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<dynamic> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No products found in this order.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true, // Important for ListView inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this inner ListView
      itemCount: products.length,
      itemBuilder: (ctx, index) {
        final product = products[index] as Map<String, dynamic>? ?? {};
        String productName = product['name']?.toString() ?? 'Unnamed Product';
        int quantity = (product['quantity'] is int) ? product['quantity'] : int.tryParse(product['quantity']?.toString() ?? '1') ?? 1;
        String price = _formatCurrency(product['price']);
        String? imageUrl = product['imageUrl']?.toString();
        String variant = product['variant']?.toString() ?? '';

        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            // side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 30),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variant.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(variant, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                        ),
                      const SizedBox(height: 4),
                      Text('Qty: $quantity', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(price, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShippingDetailsCard(BuildContext context, String name, String address, String phone) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(address, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text('Phone: $phone', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(BuildContext context, String method, String transId, String payStatus, String subtotal, String shipping, String discount, String total) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Method:', method),
            if (transId != 'N/A') _buildDetailRow(context, 'Transaction ID:', transId),
            _buildDetailRow(context, 'Status:', payStatus, valueColor: _getStatusColor(payStatus, theme)),
            const Divider(height: 20, thickness: 0.5),
            _buildDetailRow(context, 'Subtotal:', subtotal),
            _buildDetailRow(context, 'Shipping Fee:', shipping),
            if (discount != _formatCurrency(0)) // Only show discount if it's not zero
              _buildDetailRow(context, 'Discount:', discount, valueColor: Colors.green.shade700),
            const Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(total, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: valueColor),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}