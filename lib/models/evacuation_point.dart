class EvacuationPoint {
  const EvacuationPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.capacity,
    this.currentOccupancy,
    this.status = 'active',
    this.description,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final int? capacity;
  final int? currentOccupancy;
  final String status;
  final String? description;

  factory EvacuationPoint.fromJson(Map<String, dynamic> json) {
    return EvacuationPoint(
      id: int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address']?.toString(),
      capacity: json['capacity'] == null
          ? null
          : int.parse(json['capacity'].toString()),
      currentOccupancy: json['current_occupancy'] == null
          ? null
          : int.parse(json['current_occupancy'].toString()),
      status: json['status']?.toString() ?? 'active',
      description: json['description']?.toString(),
    );
  }
}