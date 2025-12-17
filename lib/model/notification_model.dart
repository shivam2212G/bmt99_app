import 'package:hive/hive.dart';
part 'notification_model.g.dart';


@HiveType(typeId: 0)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String heading;

  @HiveField(1)
  final String? content;

  @HiveField(2)
  final String? bigPicture;

  // @HiveField(3)
  // final String? androidBigPicture;

  @HiveField(4)
  final DateTime receivedAt;

  NotificationModel({
    required this.heading,
    this.content,
    this.bigPicture,
    // this.androidBigPicture,
    required this.receivedAt,
  });
}
