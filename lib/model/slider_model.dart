class SliderModel {
  final int sliderId;
  final String sliderTitle;
  final String? sliderDescription;
  final String sliderImage;

  SliderModel({
    required this.sliderId,
    required this.sliderTitle,
    this.sliderDescription,
    required this.sliderImage,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      sliderId: json['slider_id'],
      sliderTitle: json['slider_title'],
      sliderDescription: json['slider_description'],
      sliderImage: json['slider_image'],
    );
  }
}
