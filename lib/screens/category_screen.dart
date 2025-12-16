import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../model/category_model.dart';
import '../services/category_service.dart';
import '../baseapi.dart';
import '../widget/MainNavigation.dart';
import 'category_productscreen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? name, email, avatar;
  List<CategoryModel> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadUserData();
  }

  Future<void> loadCategories() async {
    categories = await CategoryService().fetchCategories();
    setState(() => loading = false);
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      email = prefs.getString('email');
      avatar = prefs.getString('avatar');
    });
  }

  // Shimmer effect for category cards
  Widget _buildCategoryCardShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _getAspectRatio(constraints.maxWidth),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Shimmer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade300,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Responsive grid calculations - ALWAYS 2 columns on mobile portrait
  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 2; // Changed from 1 to 2 for mobile portrait
  }

  double _getAspectRatio(double width) {
    if (width > 1200) return 0.9;
    if (width > 900) return 0.95;
    if (width > 600) return 1.0;
    return 1.0; // Square aspect ratio for mobile
  }

  // Truncate text with ellipsis
  String _truncateText(String text, {int maxLength = 25}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Category Card Widget
  Widget _buildCategoryCard(CategoryModel category, int index) {
    final colorScheme = [
      [Colors.green.shade100, Colors.green.shade600],
      [Colors.blue.shade100, Colors.blue.shade600],
      [Colors.orange.shade100, Colors.orange.shade600],
      [Colors.purple.shade100, Colors.purple.shade600],
      [Colors.red.shade100, Colors.red.shade600],
      [Colors.teal.shade100, Colors.teal.shade600],
    ];

    final colors = colorScheme[index % colorScheme.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreen(
              category: category,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colors[0],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallCard = constraints.maxWidth < 180;

            return Column(
              children: [
                // Image Section
                Expanded(
                  flex: isSmallCard ? 1 : 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: Image.network(
                        "${ApiConfig.baseUrl}/${category.categoryImage}",
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              color: colors[1],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colors[0],
                            child: Center(
                              child: Icon(
                                Icons.category_rounded,
                                color: colors[1],
                                size: isSmallCard ? 30 : 50,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Content Section
                Expanded(
                  flex: isSmallCard ? 1 : 1,
                  child: Padding(
                    padding: EdgeInsets.all(isSmallCard ? 8 : 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Category Name with responsive font size
                        Flexible(
                          child: Text(
                            _truncateText(category.categoryName, maxLength: isSmallCard ? 20 : 25),
                            style: TextStyle(
                              fontSize: isSmallCard ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: colors[1],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: isSmallCard ? 2 : 4),

                        // Description with responsive font size
                        Flexible(
                          child: Text(
                            category.categoryDescription?.isNotEmpty == true
                                ? _truncateText(category.categoryDescription!, maxLength: isSmallCard ? 15 : 20)
                                : "Explore products",
                            style: TextStyle(
                              fontSize: isSmallCard ? 10 : 12,
                              color: colors[1].withOpacity(0.7),
                              height: 1.2,
                            ),
                            maxLines: isSmallCard ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo/Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(34),
                child: Image.asset(
                  fit: BoxFit.fitHeight,
                  'assets/shoplogo.png',
                  width: 34,
                  height: 34,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Shop by category",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        toolbarHeight: 70,
        actions: [
          // User icon
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: IconButton(
              icon: Icon(
                Icons.search_rounded,
                size: 22,
                color: Colors.white.withOpacity(0.95),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigation(initialIndex: 2),
                  ),
                );
              },
              padding: const EdgeInsets.all(8),
            ),
          ),
          // Notification icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: Badge(
                label: const Text('3'),
                backgroundColor: Colors.red.shade400,
                textColor: Colors.white,
                smallSize: 18,
                child: Icon(
                  Iconsax.notification,
                  size: 22,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
              Colors.green.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
              final aspectRatio = _getAspectRatio(constraints.maxWidth);

              return Column(
                children: [
                  // Categories Grid
                  Expanded(
                    child: loading
                        ? _buildCategoryCardShimmer()
                        : categories.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: constraints.maxWidth > 600 ? 100 : 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "No categories found",
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 20 : 18,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                        : GridView.builder(
                      padding: EdgeInsets.all(
                        constraints.maxWidth > 600 ? 20 : 16,
                      ),
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: constraints.maxWidth > 600 ? 20 : 16,
                        mainAxisSpacing: constraints.maxWidth > 600 ? 20 : 16,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(
                            categories[index], index);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 100;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 6 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: isSmall ? 20 : 24),
            ),
            SizedBox(height: isSmall ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isSmall) const SizedBox(height: 2),
            if (!isSmall)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      },
    );
  }
}