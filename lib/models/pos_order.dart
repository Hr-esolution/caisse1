import 'package:isar/isar.dart';

part 'pos_order.g.dart';

@Collection()
class PosOrder {
  Id id = Isar.autoIncrement;

  int staffId;
  int? restaurantId;
  String channel; // pos
  String fulfillmentType; // on_site | pickup | delivery
  String status; // pending | paid | cancelled
  double totalPrice;
  double originalTotal;
  double discountAmount;
  bool hasDiscount;
  String? paymentMethod;
  String paymentStatus; // pending | paid
  String? customerName;
  String? customerPhone;
  String? deliveryAddress;
  String? tableNumber;
  String? note;
  int? rewardId;
  String? cancelReason;

  DateTime createdAt;
  DateTime updatedAt;

  PosOrder({
    this.id = Isar.autoIncrement,
    required this.staffId,
    this.restaurantId,
    this.channel = 'pos',
    required this.fulfillmentType,
    this.status = 'pending',
    this.totalPrice = 0.0,
    this.originalTotal = 0.0,
    this.discountAmount = 0.0,
    this.hasDiscount = false,
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.tableNumber,
    this.note,
    this.rewardId,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
  });
}
