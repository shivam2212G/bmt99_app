import 'feature_brand_model.dart';

class ProductModel {
  final int productId;
  final String productName;
  final String productDescription;
  final int productMrp;
  final int productPrice;
  final int productDiscount;
  final String productImage;
  final int productSubCategory;
  final int productStock;

  // NEW FIELD
  final FeatureBrandModel? featureBrand; // NEW

  ProductModel({
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productMrp,
    required this.productPrice,
    required this.productDiscount,
    required this.productImage,
    required this.productSubCategory,
    required this.productStock,
    this.featureBrand, // NEW ✔ CORRECT LOCATION


  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'],
      productName: json['product_name'],
      productDescription: json['product_description'] ?? "",
      productMrp: json['product_mrp'],
      productPrice: json['product_price'],
      productDiscount: json['product_discount'],
      productImage: json['product_image'],
      productSubCategory: json['sub_category_id'],
      productStock: json['product_stock'],
      featureBrand: json['featurebrand'] != null
          ? FeatureBrandModel.fromJson(json['featurebrand'])
          : null,
    );
  }
}
