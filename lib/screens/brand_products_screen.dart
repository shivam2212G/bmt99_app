import 'package:flutter/material.dart';
import '../services/brand_product_service.dart';
import '../model/product_model.dart';
import '../baseapi.dart';
import '../services/cart_service.dart';
import 'product_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrandProductsScreen extends StatefulWidget {
  final int brandId;
  final String brandName;
  final String brandImage;

  const BrandProductsScreen({
    super.key,
    required this.brandId,
    required this.brandName,
    required this.brandImage,
  });

  @override
  State<BrandProductsScreen> createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends State<BrandProductsScreen> {
  bool loading = true;
  List<ProductModel> products = [];

  @override
  void initState() {
    super.initState();
    loadBrandProducts();
  }

  Future<void> loadBrandProducts() async {
    products = await BrandProductService().fetchProductsByBrand(widget.brandId);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brandName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // BRAND HEADER IMAGE
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      "${ApiConfig.baseUrl}/${widget.brandImage}",
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(Icons.business, size: 40),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.brandName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${products.length} products available",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // PRODUCTS SECTION (Same as Best Offers UI)
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Container(
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
                Text(
                  "${widget.brandName} Products 🛍️",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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
                        color: Colors.green.withOpacity(0.3),
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

          // PRODUCT GRID
          GridView.builder(
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
    );
  }

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



  // Widget _buildProductsSection() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 15,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     margin: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Column(
  //       children: [
  //         // HEADER WITH TITLE AND BADGE
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 20),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 "${widget.brandName} Products 🛍️",
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.grey.shade800,
  //                 ),
  //               ),
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 15,
  //                   vertical: 8,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   gradient: LinearGradient(
  //                     colors: [Colors.green.shade400, Colors.blue.shade400],
  //                   ),
  //                   borderRadius: BorderRadius.circular(15),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.green.withOpacity(0.3),
  //                       blurRadius: 8,
  //                       offset: const Offset(0, 3),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Text(
  //                   "${products.length} Items",
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //
  //         // PRODUCT GRID
  //         GridView.builder(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //             crossAxisCount: 2,
  //             childAspectRatio: 0.75,
  //             crossAxisSpacing: 15,
  //             mainAxisSpacing: 15,
  //           ),
  //           padding: const EdgeInsets.symmetric(horizontal: 20),
  //           itemCount: products.length,
  //           itemBuilder: (context, index) {
  //             return _buildProductCard(products[index]);
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildProductCard(ProductModel p) {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => ProductDetailsScreen(product: p),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.05),
  //             blurRadius: 15,
  //             offset: const Offset(0, 5),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // IMAGE + DISCOUNT BADGE
  //           Stack(
  //             children: [
  //               ClipRRect(
  //                 borderRadius: const BorderRadius.vertical(
  //                   top: Radius.circular(20),
  //                 ),
  //                 child: Image.network(
  //                   "${ApiConfig.baseUrl}/${p.productImage}",
  //                   height: 140,
  //                   width: double.infinity,
  //                   fit: BoxFit.cover,
  //                   errorBuilder: (context, error, stackTrace) {
  //                     return Container(
  //                       height: 140,
  //                       width: double.infinity,
  //                       color: Colors.grey.shade200,
  //                       child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
  //                     );
  //                   },
  //                 ),
  //               ),
  //
  //               // DISCOUNT BADGE - Enhanced styling
  //               if (p.productDiscount > 0)
  //                 Positioned(
  //                   top: 12,
  //                   right: 12,
  //                   child: Container(
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 10,
  //                       vertical: 6,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         colors: [Colors.orange.shade400, Colors.red.shade400],
  //                       ),
  //                       borderRadius: BorderRadius.circular(12),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.orange.withOpacity(0.3),
  //                           blurRadius: 8,
  //                           offset: const Offset(0, 3),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Text(
  //                       "${p.productDiscount}% OFF",
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 11,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //
  //           // PRODUCT DETAILS
  //           Expanded(
  //             child: Padding(
  //               padding: const EdgeInsets.all(16),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   // PRODUCT NAME
  //                   Text(
  //                     p.productName,
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.grey.shade800,
  //                     ),
  //                   ),
  //
  //                   const SizedBox(height: 8),
  //
  //                   // REVIEWS SECTION
  //                   Row(
  //                     children: [
  //                       Icon(Icons.star, color: Colors.amber.shade600, size: 16),
  //                       const SizedBox(width: 4),
  //                       Text(
  //                         "4.5",
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: Colors.grey.shade700,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                       const SizedBox(width: 4),
  //                       Text(
  //                         "(128)",
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: Colors.grey.shade600,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //
  //                   const SizedBox(height: 8),
  //
  //                   // PRICE SECTION
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: [
  //                           Text(
  //                             "₹${p.productPrice}",
  //                             style: const TextStyle(
  //                               fontSize: 18,
  //                               fontWeight: FontWeight.bold,
  //                               color: Colors.green,
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           if (p.productDiscount > 0)
  //                             Text(
  //                               "₹${p.productMrp}",
  //                               style: const TextStyle(
  //                                 fontSize: 13,
  //                                 color: Colors.grey,
  //                                 decoration: TextDecoration.lineThrough,
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //                       if (p.productDiscount > 0)
  //                         const SizedBox(height: 4),
  //                       if (p.productDiscount > 0)
  //                         Text(
  //                           "Save ₹${(p.productMrp - p.productPrice).toStringAsFixed(0)}",
  //                           style: TextStyle(
  //                             fontSize: 11,
  //                             color: Colors.green.shade600,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                         ),
  //                     ],
  //                   ),
  //
  //                   const SizedBox(height: 12),
  //
  //                   // ADD TO CART BUTTON - Enhanced styling
  //                   SizedBox(
  //                     width: double.infinity,
  //                     child: ElevatedButton(
  //                       onPressed: () async {
  //                         final prefs = await SharedPreferences.getInstance();
  //                         final userId = prefs.getInt('user_id');
  //
  //                         if (userId == null) {
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(
  //                               content: Text("Please login to add items to cart"),
  //                               backgroundColor: Colors.orange,
  //                             ),
  //                           );
  //                           return;
  //                         }
  //
  //                         try {
  //                           final result = await CartService().addToCart(
  //                             userId: userId,
  //                             productId: p.productId,
  //                           );
  //
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             SnackBar(
  //                               content: Text(result["message"]),
  //                               backgroundColor: Colors.green,
  //                               behavior: SnackBarBehavior.floating,
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(15),
  //                               ),
  //                             ),
  //                           );
  //                         } catch (e) {
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             SnackBar(
  //                               content: const Text("Failed to add item to cart"),
  //                               backgroundColor: Colors.red.shade600,
  //                               behavior: SnackBarBehavior.floating,
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(15),
  //                               ),
  //                             ),
  //                           );
  //                         }
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.green.shade600,
  //                         foregroundColor: Colors.white,
  //                         padding: const EdgeInsets.symmetric(vertical: 12),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(15),
  //                         ),
  //                         elevation: 3,
  //                         shadowColor: Colors.green.withOpacity(0.3),
  //                       ),
  //                       child: const Text(
  //                         "Add to Cart",
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 36,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}