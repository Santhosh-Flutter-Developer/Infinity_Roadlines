class LRModel {
  final String lrId;
  final String lrNumber;
  final String entryDate;
  final String consignorId;
  final String consignorName;
  final String consigneeId;
  final String consigneeName;
  final String fromBranchId;
  final String fromBranch;
  final String toBranchId;
  final String toBranch;
  final String quantity;
  final String unitName;
  final String amount;
  final String status;
  final String billType;

  // Legacy Dummy/UI properties for unmodified screens
  final String deliveryStatus;
  final String destination;
  final double receiverLat;
  final double receiverLng;
  final double deliveredLat;
  final double deliveredLng;
  final DateTime? deliveredAt;
  final String consigneePhone;
  final String address;
  final double toPay;
  final int qty;
  final double weight;
  final double cooly;
  final double account;
  final double paid;
  final String extraCharges;
  final double chargeAmount;
  final String consignorPhone;

  LRModel({
    this.lrId = '',
    this.lrNumber = '',
    this.entryDate = '',
    this.consignorId = '',
    this.consignorName = '',
    this.consigneeId = '',
    this.consigneeName = '',
    this.fromBranchId = '',
    this.fromBranch = '',
    this.toBranchId = '',
    this.toBranch = '',
    this.quantity = '',
    this.unitName = '',
    this.amount = '',
    this.status = '',
    this.billType = '',
    
    // Default legacy fields
    this.deliveryStatus = 'pending',
    this.destination = '',
    this.receiverLat = 0.0,
    this.receiverLng = 0.0,
    this.deliveredLat = 0.0,
    this.deliveredLng = 0.0,
    this.deliveredAt,
    this.consigneePhone = '',
    this.address = '',
    this.toPay = 0.0,
    this.qty = 0,
    this.weight = 0.0,
    this.cooly = 0.0,
    this.account = 0.0,
    this.paid = 0.0,
    this.extraCharges = '',
    this.chargeAmount = 0.0,
    this.consignorPhone = '',
  });

  factory LRModel.fromJson(Map<String, dynamic> json) {
    return LRModel(
      lrId: json['lr_id']?.toString() ?? '',
      lrNumber: json['lr_number']?.toString() ?? '',
      entryDate: json['entry_date']?.toString() ?? '',
      consignorId: json['consignor_id']?.toString() ?? '',
      consignorName: json['consignor_name']?.toString() ?? '',
      consigneeId: json['consignee_id']?.toString() ?? '',
      consigneeName: json['consignee_name']?.toString() ?? '',
      fromBranchId: json['from_branch_id']?.toString() ?? '',
      fromBranch: json['from_branch']?.toString() ?? '',
      toBranchId: json['to_branch_id']?.toString() ?? '',
      toBranch: json['to_branch']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      billType: json['bill_type']?.toString() ?? '',
      
      // Parse destination coordinates dynamically 
      receiverLat: double.tryParse(json['destination_latitude']?.toString() ?? json['receiver_lat']?.toString() ?? '') ?? 0.0,
      receiverLng: double.tryParse(json['destination_longitude']?.toString() ?? json['receiver_lng']?.toString() ?? '') ?? 0.0,
    );
  }

  LRModel copyWith({
    String? deliveryStatus,
    DateTime? deliveredAt,
    double? deliveredLat,
    double? deliveredLng,
  }) {
    return LRModel(
      lrId: lrId,
      lrNumber: lrNumber,
      entryDate: entryDate,
      consignorId: consignorId,
      consignorName: consignorName,
      consigneeId: consigneeId,
      consigneeName: consigneeName,
      fromBranchId: fromBranchId,
      fromBranch: fromBranch,
      toBranchId: toBranchId,
      toBranch: toBranch,
      quantity: quantity,
      unitName: unitName,
      amount: amount,
      status: status,
      billType: billType,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      destination: destination,
      receiverLat: receiverLat,
      receiverLng: receiverLng,
      deliveredLat: deliveredLat ?? this.deliveredLat,
      deliveredLng: deliveredLng ?? this.deliveredLng,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      consigneePhone: consigneePhone,
      address: address,
      toPay: toPay,
      qty: qty,
      weight: weight,
      cooly: cooly,
      account: account,
      paid: paid,
      extraCharges: extraCharges,
      chargeAmount: chargeAmount,
      consignorPhone: consignorPhone,
    );
  }
}
