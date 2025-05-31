import 'package:cached_network_image/cached_network_image.dart'; // Add to pubspec.yaml
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// import 'package:shimmer/shimmer.dart'; // Optional: for shimmer effect

// --- Placeholder Model Classes (Define these properly based on your data) ---
class Order {
  final String id;
  final DateTime orderDate;
  final String status;
  final List<ProductItem> items;
  final ShippingInfo shippingInfo;
  final PaymentInfo paymentInfo;
  final double subtotal;
  final double shippingFee;
  final double discountApplied;
  final double totalAmount;
  final String? rawOrderIdFromData; // To display the order ID from data if available

  Order({
    required this.id,
    required this.orderDate,
    required this.status,
    required this.items,
    required this.shippingInfo,
    required this.paymentInfo,
    required this.subtotal,
    required this.shippingFee,
    required this.discountApplied,
    required this.totalAmount,
    this.rawOrderIdFromData,
  });

  // Example Factory (YOU NEED TO IMPLEMENT THIS THOROUGHLY)
  factory Order.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, dynamic> shippingData,
      String fallbackOrderId) {
    final data = doc.data()!;
    List<dynamic> productList = data['products'] as List<dynamic>? ?? [];

    // Helper to safely parse numbers
    num safeParseNum(dynamic value, {num defaultValue = 0.0}) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Order(
      id: doc.id,
      rawOrderIdFromData: data['orderId']?.toString() ?? fallbackOrderId,
      orderDate: (data['timestamp'] as Timestamp).toDate(),
      status: data['status']?.toString() ?? 'Pending',
      items: productList
          .map((itemData) =>
          ProductItem.fromMap(itemData as Map<String, dynamic>))
          .toList(),
      shippingInfo: ShippingInfo.fromMap(shippingData),
      paymentInfo: PaymentInfo.fromMap(
          data['paymentDetails'] as Map<String, dynamic>? ?? {}, data),
      subtotal: safeParseNum(data['subtotal']).toDouble(),
      shippingFee: safeParseNum(data['shippingFee']).toDouble(),
      discountApplied: safeParseNum(data['discountApplied'] ?? data['discount']).toDouble(),
      totalAmount: safeParseNum(data['totalAmount']).toDouble(),
    );
  }
}

class ProductItem {
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String? variant;

  ProductItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.variant,
  });

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    num safeParseNum(dynamic value, {num defaultValue = 0.0}) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    int qty = 1;
    if (map['quantity'] is int) {
      qty = map['quantity'];
    } else if (map['quantity'] is String) {
      qty = int.tryParse(map['quantity'] ?? '1') ?? 1;
    } else if (map['quantity'] is num) {
      qty = (map['quantity'] as num).toInt();
    }

    return ProductItem(
      name: map['name']?.toString() ?? 'Unnamed Product',
      quantity: qty,
      price: safeParseNum(map['price']).toDouble(),
      imageUrl: map['imageUrl']?.toString(),
      variant: map['variant']?.toString() ?? '',
    );
  }
}

class ShippingInfo {
  final String name;
  final String fullAddress;
  final String phone;

  ShippingInfo(
      {required this.name, required this.fullAddress, required this.phone});

  factory ShippingInfo.fromMap(Map<String, dynamic> map) {
    String ad1 = map['addressLine1']?.toString() ?? '';
    String ad2 = map['addressLine2']?.toString() ?? '';
    String city = map['city']?.toString() ?? '';
    String st = map['state']?.toString() ?? '';
    String zip = map['zip']?.toString() ?? '';
    List<String> parts = [ad1, ad2, city, st, zip].where((s) => s.isNotEmpty).toList();
    String calculatedFullAddress = parts.isNotEmpty ? parts.join(', ') : (map['name'] != 'N/A' ? 'Detailed address not provided' : 'N/A');
    if (map['fullAddress'] != null && map['fullAddress'].toString().isNotEmpty && map['fullAddress'] != 'N/A') {
      calculatedFullAddress = map['fullAddress'].toString();
    }


    return ShippingInfo(
      name: map['name']?.toString() ?? 'N/A',
      fullAddress: calculatedFullAddress,
      phone: map['phone']?.toString() ?? 'N/A',
    );
  }

  static Map<String, dynamic> defaultAddress = {
    'name': 'N/A',
    'phone': 'N/A',
    'addressLine1': 'Address not available',
    'addressLine2': '',
    'city': '',
    'state': '',
    'zipCode': '',
    'fullAddress': 'Address not available',
  };
  static Map<String, dynamic> errorAddress(String message) => {
    'name': 'Error',
    'phone': '',
    'fullAddress': message,
  };
}

class PaymentInfo {
  final String method;
  final String transactionId;
  final String status;

  PaymentInfo(
      {required this.method,
        required this.transactionId,
        required this.status});

  factory PaymentInfo.fromMap(
      Map<String, dynamic> paymentDetails, Map<String, dynamic> orderData) {
    return PaymentInfo(
      method: paymentDetails['paymentMethod']?.toString() ??
          orderData['paymentMethod']?.toString() ??
          'N/A',
      transactionId: orderData['razorpayPaymentId']?.toString() ??
          paymentDetails['transactionId']?.toString() ??
          paymentDetails['orderId']?.toString() ?? // Fallback if transactionId is nested under orderId in paymentDetails
          'N/A',
      status: paymentDetails['status']?.toString() ?? 'N/A',
    );
  }
}
// --- End Model Classes ---

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Order> _orderDetailsFuture;

  @override
  void initState() {
    super.initState();
    _orderDetailsFuture = _fetchOrderWithShippingDetails();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchOrderDocument() {
    return FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();
  }

  Future<Map<String, dynamic>> _fetchShippingAddressFromUser(
      String? userId) async {
    if (userId == null || userId.isEmpty) {
      // print("OrderDetailsScreen: User ID is empty, cannot fetch address.");
      return ShippingInfo.defaultAddress;
    }

    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data()!;
        Map<String, dynamic> fetchedAddress = {};

        fetchedAddress['name'] = userData['name']?.toString() ??
            userData['displayName']?.toString() ??
            'N/A';
        fetchedAddress['phone'] = userData['phone']?.toString() ??
            userData['phoneNumber']?.toString() ??
            'N/A';

        String addressLine1 = '',
            addressLine2 = '',
            city = '',
            stateVal = '', // Renamed to avoid conflict with State class
            zipCode = '';

        if (userData.containsKey('address') && userData['address'] is Map) {
          Map<String, dynamic> addressSubMap =
          Map<String, dynamic>.from(userData['address']);
          addressLine1 = addressSubMap['addressLine1']?.toString() ??
              addressSubMap['street']?.toString() ??
              '';
          addressLine2 = addressSubMap['addressLine2']?.toString() ?? '';
          city = addressSubMap['city']?.toString() ?? '';
          stateVal = addressSubMap['state']?.toString() ?? '';
          zipCode = addressSubMap['zip']?.toString() ??
              addressSubMap['postalCode']?.toString() ??
              '';
        } else {
          addressLine1 = userData['addressLine1']?.toString() ??
              userData['street']?.toString() ??
              '';
          city = userData['city']?.toString() ?? '';
          stateVal = userData['state']?.toString() ?? '';
          zipCode = userData['zip']?.toString() ??
              userData['postalCode']?.toString() ??
              '';
        }

        fetchedAddress['addressLine1'] = addressLine1;
        fetchedAddress['addressLine2'] = addressLine2;
        fetchedAddress['city'] = city;
        fetchedAddress['state'] = stateVal;
        fetchedAddress['zipCode'] = zipCode;

        List<String> addressParts = [
          addressLine1,
          addressLine2,
          city,
          stateVal,
          zipCode
        ].where((s) => s.isNotEmpty).toList();
        fetchedAddress['fullAddress'] = addressParts.isNotEmpty
            ? addressParts.join(', ')
            : (fetchedAddress['name'] != 'N/A'
            ? 'Detailed address not provided'
            : 'N/A');
        return fetchedAddress;
      } else {
        return ShippingInfo.defaultAddress; // User not found, return default
      }
    } catch (e) {
      // print("OrderDetailsScreen: Error fetching shipping address for user $userId: $e");
      return ShippingInfo.errorAddress("Could not load shipping address.");
    }
  }

  Future<Order> _fetchOrderWithShippingDetails() async {
    try {
      final orderDoc = await _fetchOrderDocument();
      if (!orderDoc.exists || orderDoc.data() == null) {
        throw Exception('Order not found.');
      }
      final orderData = orderDoc.data()!;
      final String? userId = orderData['userId']?.toString();

      final shippingData = await _fetchShippingAddressFromUser(userId);
      return Order.fromFirestore(orderDoc, shippingData, widget.orderId);
    } catch (e) {
      // print("Error in _fetchOrderWithShippingDetails: $e");
      rethrow; // Propagate error to FutureBuilder
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      return DateFormat('dd MMM, yyyy - hh:mm a').format(dateTime.toLocal());
    } catch (e) {
      return dateTime.toIso8601String(); // Fallback
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'N/A';
    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return numberFormat.format(amount);
  }

  Color _getStatusColor(String? status, ThemeData theme) {
    status = status?.toLowerCase() ?? "";
    if (status.contains('delivered') || status.contains('completed')) {
      return Colors.green.shade700;
    } else if (status.contains('shipped') || status.contains('processing')) {
      return Colors.orange.shade700;
    } else if (status.contains('cancelled') || status.contains('failed')) {
      return theme.colorScheme.error;
    }
    return theme.textTheme.bodyMedium?.color ?? Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 22, // Slightly reduced for balance
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        elevation: 1, // Softer elevation
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.lightBlue.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // foregroundColor: theme.colorScheme.onSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: FutureBuilder<Order>(
        future: _orderDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton(context); // Or Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorView(context, snapshot.error);
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Order not found.'));
          }

          final Order order = snapshot.data!;
          return _buildOrderContent(context, theme, order);
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    // Replace with Shimmer effect for better UX
    return const Center(child: CircularProgressIndicator());
    // Example with Shimmer (add shimmer package to pubspec.yaml):
    /*
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonLine(width: 200, height: 24),
            const SizedBox(height: 20),
            _buildSkeletonCard(),
            const SizedBox(height: 20),
            _buildSkeletonLine(width: 150, height: 20),
            const SizedBox(height: 10),
            _buildSkeletonCard(itemCount: 2),
            const SizedBox(height: 20),
            _buildSkeletonLine(width: 180, height: 20),
             const SizedBox(height: 10),
            _buildSkeletonCard(),
          ],
        ),
      ),
    );
    */
  }

  Widget _buildSkeletonLine({required double width, double height = 16.0}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer will color this
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
    );
  }

  Widget _buildSkeletonCard({int itemCount = 1}) {
    return Card(
      elevation: 0, // Shimmer base cards are usually flat
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(itemCount * 2, (index) => _buildSkeletonLine(width: double.infinity)),
        ),
      ),
    );
  }


  Widget _buildErrorView(BuildContext context, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 50),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Order',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().contains("Order not found")
                  ? "We couldn't find the order you're looking for."
                  : 'An unexpected error occurred. Please try again later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: () {
                  setState(() {
                    _orderDetailsFuture = _fetchOrderWithShippingDetails();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderContent(
      BuildContext context,
      ThemeData theme,
      Order order,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildOrderSummarySection(context, theme, order),
          const SizedBox(height: 24),
          _buildShippingSection(context, theme, order.shippingInfo),
          const SizedBox(height: 24),
          _buildItemsOrderedSection(context, theme, order.items, order.id),
          const SizedBox(height: 24),
          _buildPaymentSection(context, theme, order.paymentInfo, order),
          const SizedBox(height: 24),
          // Optional: Add action buttons like "Track Order", "Reorder" etc.
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {IconData? icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // Increased bottom padding
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: GoogleFonts.lato(
                fontSize: 18, // Was titleLarge, which can be quite big
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, ThemeData theme, Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order ID: ${order.rawOrderIdFromData ?? order.id}', // Display Firestore Order ID
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Placed on ${_formatDateTime(order.orderDate)}',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status, theme).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                order.status.isNotEmpty ? order.status[0].toUpperCase() + order.status.substring(1) : "Unknown",
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: _getStatusColor(order.status, theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildShippingSection(BuildContext context, ThemeData theme, ShippingInfo shippingInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Shipping Information', icon: Icons.local_shipping_outlined),
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero, // Section title provides padding
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shippingInfo.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(shippingInfo.fullAddress, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis,),
                const SizedBox(height: 8),
                if (shippingInfo.phone.isNotEmpty && shippingInfo.phone != 'N/A')
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 6),
                      Text(shippingInfo.phone, style: theme.textTheme.bodyMedium),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsOrderedSection(BuildContext context, ThemeData theme, List<ProductItem> items, String orderId) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Items Ordered (0)', icon: Icons.shopping_bag_outlined),
          const Card(
            elevation: 1.5,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No products found in this order.')),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Items Ordered (${items.length})', icon: Icons.shopping_bag_outlined),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (ctx, index) {
            final product = items[index];
            return _ProductListItem(product: product, theme: theme, formatCurrency: _formatCurrency);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentSection(BuildContext context, ThemeData theme, PaymentInfo paymentInfo, Order order) {
    bool showDiscountRow = order.discountApplied != 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Payment Summary', icon: Icons.payment_outlined),
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(context, 'Method:', paymentInfo.method),
                if (paymentInfo.transactionId.isNotEmpty && paymentInfo.transactionId != 'N/A')
                  _buildDetailRow(context, 'Transaction ID:', paymentInfo.transactionId),
                if (paymentInfo.status.isNotEmpty && paymentInfo.status != 'N/A')
                  _buildDetailRow(context, 'Payment Status:', paymentInfo.status, valueColor: _getStatusColor(paymentInfo.status, theme)),
                const Divider(height: 24, thickness: 0.5), // Increased height for divider
                _buildDetailRow(context, 'Subtotal:', _formatCurrency(order.subtotal)),
                _buildDetailRow(context, 'Shipping Fee:', _formatCurrency(order.shippingFee)),
                if (showDiscountRow)
                  _buildDetailRow(context, 'Discount:', '-${_formatCurrency(order.discountApplied)}', valueColor: Colors.green.shade700),
                const Divider(height: 24, thickness: 0.8), // Thicker divider for total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount:', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                    Text(_formatCurrency(order.totalAmount), style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0), // Increased vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? theme.textTheme.bodyLarge?.color, // Use bodyLarge for value
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Separate widget for Product List Item for better organization
class _ProductListItem extends StatelessWidget {
  const _ProductListItem({
    Key? key,
    required this.product,
    required this.theme,
    required this.formatCurrency,
  }) : super(key: key);

  final ProductItem product;
  final ThemeData theme;
  final String Function(double?) formatCurrency;


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8, // Subtle elevation for item cards
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5) // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: product.imageUrl!,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    width: 75,
                    height: 75,
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor))),
                errorWidget: (context, url, error) => Container(
                  width: 75,
                  height: 75,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 35),
                ),
              )
                  : Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 35),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.titleMedium?.color),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.variant != null && product.variant!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(product.variant!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 12)),
                    ),
                  const SizedBox(height: 6),
                  Text('Qty: ${product.quantity}', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(product.price),
                    style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}