import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../baseapi.dart';
import '../model/product_model.dart';
import '../model/category_model.dart';
import '../model/feature_brand_model.dart';
import '../services/new_products_service.dart';
import '../services/search_service.dart';
import '../services/cart_service.dart';
import '../services/category_service.dart';
import '../services/feature_brand_service.dart';

import '../widget/bottom_navigation_bar.dart';
import 'home_screen.dart';
import 'category_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_details_screen.dart';

class NewProducts extends StatefulWidget {
  const NewProducts({super.key});

  @override
  State<NewProducts> createState() => _NewProductsState();
}

class _NewProductsState extends State<NewProducts> {
  int _currentIndex = 2;

  bool loadingProducts = true;

  List<ProductModel> products = [];

  // filters data
  List<CategoryModel> _categories = [];
  List<FeatureBrandModel> _brands = [];

  // filter state
  String _searchText = "";
  String _sortOption = 'relevance'; // relevance, price_low_high, price_high_low, discount_high_low
  int? _selectedCategoryId;
  int? _selectedBrandId;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadNewProducts(),
      _loadFilterSources(),
    ]);
  }

  Future<void> _loadNewProducts() async {
    products = await NewProductService().fetchNewProducts();
    setState(() => loadingProducts = false);
  }

  Future<void> _loadFilterSources() async {
    _categories = await CategoryService().fetchCategories();
    _brands = await FeatureBrandService().fetchFeatureBrands();
    setState(() {});
  }

  bool _hasActiveFilters() {
    return _searchText.isNotEmpty ||
        _sortOption != 'relevance' ||
        _selectedCategoryId != null ||
        _selectedBrandId != null ||
        _minPriceController.text.isNotEmpty ||
        _maxPriceController.text.isNotEmpty;
  }

  Future<void> _fetchWithFilters() async {
    // if NO filters and NO search -> load default new-products
    if (!_hasActiveFilters()) {
      setState(() => loadingProducts = true);
      await _loadNewProducts();
      return;
    }

    setState(() => loadingProducts = true);

    int? minPrice =
    _minPriceController.text.isNotEmpty ? int.tryParse(_minPriceController.text) : null;
    int? maxPrice =
    _maxPriceController.text.isNotEmpty ? int.tryParse(_maxPriceController.text) : null;

    products = await SearchService().searchProducts(
      query: _searchText.isNotEmpty ? _searchText : null,
      sort: _sortOption != 'relevance' ? _sortOption : null,
      categoryId: _selectedCategoryId,
      brandId: _selectedBrandId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    setState(() => loadingProducts = false);
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CategoryScreen()),
        );
        break;
      case 2:
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

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Products"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // ------------------- SEARCH FIELD -------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                _searchText = value;
                _fetchWithFilters();
              },
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ------------------- FILTER PANEL (STYLE B) -------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SORT + CATEGORY
                  Row(
                    children: [
                      // SORT
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortOption,
                          decoration: const InputDecoration(
                            labelText: "Sort",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'relevance', child: Text("Relevance")),
                            DropdownMenuItem(
                                value: 'price_low_high',
                                child: Text("Price: Low to High")),
                            DropdownMenuItem(
                                value: 'price_high_low',
                                child: Text("Price: High to Low")),
                            DropdownMenuItem(
                                value: 'discount_high_low',
                                child: Text("Discount: High to Low")),
                          ],
                          onChanged: (val) {
                            _sortOption = val ?? 'relevance';
                            _fetchWithFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // CATEGORY
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text("All Categories"),
                            ),
                            ..._categories.map(
                                  (c) => DropdownMenuItem<int>(
                                value: c.categoryId,
                                child: Text(
                                  c.categoryName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            _selectedCategoryId = val;
                            _fetchWithFilters();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // BRAND
                  DropdownButtonFormField<int>(
                    value: _selectedBrandId,
                    decoration: const InputDecoration(
                      labelText: "Brand",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text("All Brands"),
                      ),
                      ..._brands.map(
                            (b) => DropdownMenuItem<int>(
                          value: b.featureBrandId,
                          child: Text(
                            b.featureBrandName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      _selectedBrandId = val;
                      _fetchWithFilters();
                    },
                  ),

                  const SizedBox(height: 8),

                  // PRICE RANGE ROW
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Min Price",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _fetchWithFilters(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Max Price",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _fetchWithFilters(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // RESET BUTTON
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchText = "";
                          _sortOption = 'relevance';
                          _selectedCategoryId = null;
                          _selectedBrandId = null;
                          _minPriceController.clear();
                          _maxPriceController.clear();
                        });
                        _fetchWithFilters();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Clear Filters"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ------------------- PRODUCT GRID -------------------
          Expanded(
            child: loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? const Center(
              child: Text(
                "No products found",
                style: TextStyle(fontSize: 18),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
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

  // ------------------- PRODUCT CARD -------------------
  Widget _buildProductCard(ProductModel p) {
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
          color: Colors.white,
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
            // IMAGE + DISCOUNT
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    "${ApiConfig.baseUrl}/${p.productImage}",
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
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
                        borderRadius: BorderRadius.circular(8),
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

            // DETAILS
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          decoration: TextDecoration.lineThrough,
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
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
  }
}
