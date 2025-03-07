import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void updateIndex(int index, BuildContext context) {
    _selectedIndex = index;
    Provider.of<CartProvider>(context, listen: false).fetchCart(); // ✅ Ensure cart updates on tab switch
    notifyListeners();
  }
}
