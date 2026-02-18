import 'package:isar/isar.dart';

part 'pos_order_item.g.dart';

@Collection()
class PosOrderItem {
  Id id = Isar.autoIncrement;

  int orderId;
  int productId;
  String productName;
  double unitPrice;
  int quantity;

  DateTime createdAt;

  PosOrderItem({
    this.id = Isar.autoIncrement,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.createdAt,
  });
}
