class CategoryModel {
  final int categoryId;
  final String categoryName;
  final String? categoryDescription;
  final String categoryImage;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    required this.categoryImage,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryDescription: json['category_description'],
      categoryImage: json['category_image'],
    );
  }
}
