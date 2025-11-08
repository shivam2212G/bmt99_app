import 'package:bmt99_app/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/category_model.dart';
import '../model/product_model.dart';
import '../services/cart_service.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../widget/bottom_navigation_bar.dart';
import '../baseapi.dart';
import 'home_screen.dart';
import 'new_products.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class CategoryScreen extends StatefulWidget {
  final int? selectedCategoryId;

  const CategoryScreen({super.key, this.selectedCategoryId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _currentIndex = 1;

  List<CategoryModel> categories = [];
  List<ProductModel> products = [];

  int selectedCatIndex = 0;
  bool loading = true;
  bool productLoading = false;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    categories = await CategoryService().fetchCategories();

    if (widget.selectedCategoryId != null) {
      selectedCatIndex = categories.indexWhere(
        (c) => c.categoryId == widget.selectedCategoryId,
      );
      if (selectedCatIndex == -1) selectedCatIndex = 0;
    } else {
      selectedCatIndex = 0;
    }

    await loadProducts(categories[selectedCatIndex].categoryId);

    setState(() => loading = false);
  }

  Future<void> loadProducts(int categoryId) async {
    setState(() => productLoading = true);
    products = await ProductService().getProductsByCategory(categoryId);
    setState(() => productLoading = false);
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewProducts()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  // Helper function to get icons based on category name
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'electronics':
        return Icons.electrical_services;
      case 'clothing':
        return Icons.checkroom;
      case 'food':
        return Icons.restaurant;
      case 'sports':
        return Icons.sports_baseball;
      case 'books':
        return Icons.menu_book;
      case 'beauty':
        return Icons.spa;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // TOP HORIZONTAL CATEGORY LIST
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      bool isSelected = selectedCatIndex == index;

                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            selectedCatIndex = index;
                          });
                          await loadProducts(cat.categoryId);
                        },
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Colors.green
                                : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Text(
                              cat.categoryName,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // CATEGORY IMAGE + NAME + DESC
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "${ApiConfig.baseUrl}/${categories[selectedCatIndex].categoryImage}",
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Name
                      Text(
                        categories[selectedCatIndex].categoryName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Description
                      Text(
                        categories[selectedCatIndex].categoryDescription ??
                            "No description available",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // PRODUCTS SECTION
                Expanded(
                  child: productLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsScreen(product: p),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ----------- IMAGE + DISCOUNT BADGE ----------
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child: Image.network(
                                            "${ApiConfig.baseUrl}/${p.productImage}",
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                              
                                        // DISCOUNT BADGE
                                        if (p.productDiscount > 0)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "${p.productDiscount}% OFF",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                              
                                    // ----------- PRODUCT DETAILS ----------
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Name
                                          Text(
                                            p.productName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                              
                                          const SizedBox(height: 6),
                              
                                          // PRICE + MRP
                                          Row(
                                            children: [
                                              Text(
                                                "₹${p.productPrice}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "₹${p.productMrp}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  decoration:
                                                      TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ),
                              
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () async {
                              
                                                final prefs = await SharedPreferences.getInstance();
                                                final userId = prefs.getInt('user_id');
                              
                                                if (userId == null) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text("Login required")),
                                                  );
                                                  return;
                                                }
                              
                                                try {
                                                  final result = await CartService().addToCart(
                                                    userId: userId,
                                                    productId: p.productId,
                                                  );
                              
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(result["message"]),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  print(userId);
                                                  print(e);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text("Something went wrong!"),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade600,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text("Add to Cart"),
                                            ),
                                          ),
                              
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
