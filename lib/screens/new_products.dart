import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
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
  String? name, email, avatar;

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
    loadUserData();
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
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      email = prefs.getString('email');
      avatar = prefs.getString('avatar');
    });
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


  // Shimmer effect for products grid
  Widget _buildProductGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image shimmer
              Shimmer(
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer(
                            child: Container(
                              height: 14,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Shimmer(
                            child: Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer(
                            child: Container(
                              height: 16,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Shimmer(
                            child: Container(
                              height: 36,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo/Icon with gradient
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.new_releases_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Title with improved styling
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "NEW PRODUCTS",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        "Discover latest items",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 1 + 0.1 * math.sin(value * 2 * math.pi),
                            child: child,
                          );
                        },
                        child: const Text(
                          "🆕",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        toolbarHeight: 80,
        actions: [
          // Notification icon with improved badge
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Iconsax.notification, size: 22),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade800, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade400.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Search icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ------------------- SEARCH FIELD -------------------
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  _searchText = value;
                  _fetchWithFilters();
                },
                decoration: const InputDecoration(
                  hintText: "Search new products...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER WITH CLEAR BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_hasActiveFilters())
                        GestureDetector(
                          onTap: () {
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.clear, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  "Clear",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // SORT + CATEGORY COMPACT ROW
                  Row(
                    children: [
                      // SORT - COMPACT
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _sortOption,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            items: const [
                              DropdownMenuItem(value: 'relevance', child: Text("Relevance")),
                              DropdownMenuItem(value: 'price_low_high', child: Text("Price: Low to High")),
                              DropdownMenuItem(value: 'price_high_low', child: Text("Price: High to Low")),
                              DropdownMenuItem(value: 'discount_high_low', child: Text("Discount: High to Low")),
                            ],
                            onChanged: (val) {
                              _sortOption = val ?? 'relevance';
                              _fetchWithFilters();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // CATEGORY - COMPACT
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<int>(
                            value: _selectedCategoryId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            hint: const Text("Category", style: TextStyle(fontSize: 13)),
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
                                    style: const TextStyle(fontSize: 13),
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // BRAND + PRICE COMPACT ROW
                  Row(
                    children: [
                      // BRAND - COMPACT
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<int>(
                            value: _selectedBrandId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            hint: const Text("Brand", style: TextStyle(fontSize: 13)),
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
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              _selectedBrandId = val;
                              _fetchWithFilters();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // PRICE RANGE - COMPACT
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Min ₹",
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                onSubmitted: (_) => _fetchWithFilters(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Max ₹",
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                onSubmitted: (_) => _fetchWithFilters(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ACTIVE FILTERS INDICATOR
                  if (_hasActiveFilters()) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Active filters applied",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------- PRODUCTS SECTION -------------------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // HEADER WITH TITLE AND BADGE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Products",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.blue.shade400],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            "${products.length} Items",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PRODUCT GRID WITH SHIMMER
                  loadingProducts
                      ? _buildProductGridShimmer()
                      : products.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No products found",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try adjusting your filters",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                      : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(products[index]);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ------------------- PRODUCT CARD (Matching Upper Design) -------------------
  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Image.network(
                      "${ApiConfig.baseUrl}/${product.productImage}",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade300,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            color: Colors.grey.shade400,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Discount Badge
                if (product.productDiscount > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "${product.productDiscount}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Brand Badge
                if (product.featureBrand?.featureBrandName != null &&
                    product.featureBrand!.featureBrandName!.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.featureBrand!.featureBrandName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name with character limit
                        Text(
                          product.productName.length > 17
                              ? '${product.productName.substring(0, 17)}...'
                              : product.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber.shade600,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "4.5",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "(128)",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Price and Add to Cart
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Section
                        Row(
                          children: [
                            Text(
                              "₹${product.productPrice}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (product.productMrp != product.productPrice)
                              Text(
                                "₹${product.productMrp}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Add to Cart Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final userId = prefs.getInt('user_id');

                              if (userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please login to add items to cart"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                final result = await CartService().addToCart(
                                  userId: userId,
                                  productId: product.productId,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result["message"]),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Failed to add item to cart"),
                                    backgroundColor: Colors.red.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.shopping_cart, size: 16),
                            label: const Text(
                              "Add to Cart",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}