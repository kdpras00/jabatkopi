class ReservationModel {
  final int id;
  final int tableId;
  final String customerName;
  final DateTime reservationTime;
  final int guestCount;
  final String status;

  ReservationModel({
    required this.id,
    required this.tableId,
    required this.customerName,
    required this.reservationTime,
    required this.guestCount,
    required this.status,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      tableId: json['table_id'],
      customerName: json['customer_name'] ?? '',
      reservationTime: DateTime.parse(json['reservation_time']),
      guestCount: json['guest_count'] ?? 1,
      status: json['status'] ?? 'pending',
    );
  }
}
