import 'project_form_models.dart';

/// Adresse postale (GeoPlat / `FullAddress` Java).
class FullAddressOption {
  const FullAddressOption({
    required this.label,
    this.street,
    this.postcode,
    this.city,
    this.lon,
    this.lat,
  });

  final String label;
  final String? street;
  final String? postcode;
  final String? city;
  final double? lon;
  final double? lat;

  Map<String, dynamic> toJson() => {
        'label': label,
        if (street != null && street!.isNotEmpty) 'street': street,
        if (postcode != null && postcode!.isNotEmpty) 'postcode': postcode,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (lon != null) 'lon': lon,
        if (lat != null) 'lat': lat,
      };

  static FullAddressOption? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final label = map['label']?.toString().trim();
    if (label == null || label.isEmpty) return null;
    return FullAddressOption(
      label: label,
      street: map['street']?.toString(),
      postcode: map['postcode']?.toString(),
      city: map['city']?.toString(),
      lon: _parseDouble(map['lon']),
      lat: _parseDouble(map['lat']),
    );
  }

  static double? _parseDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }
}

/// Corps `POST /api/v1/places`.
class CreateSpatialUnitRequest {
  const CreateSpatialUnitRequest({
    required this.organizationId,
    required this.name,
    required this.typeConceptId,
    this.address,
  });

  final int organizationId;
  final String name;
  final int typeConceptId;
  final FullAddressOption? address;

  Map<String, dynamic> toJson() => {
        'organizationId': organizationId,
        'name': name.trim(),
        'typeConceptId': typeConceptId,
        if (address != null) 'address': address!.toJson(),
      };
}

/// Lieu affiché dans la liste de gestion (cache local).
class PlaceListItem {
  const PlaceListItem({
    required this.place,
    required this.pendingSync,
    this.pendingDelete = false,
    this.typeConceptId,
    this.address,
  });

  final SpatialUnitOption place;
  final bool pendingSync;
  final bool pendingDelete;
  final int? typeConceptId;
  final FullAddressOption? address;
}

/// Détail `GET /api/v1/places/{id}`.
class PlaceDetail {
  const PlaceDetail({
    required this.id,
    required this.name,
    this.code,
    this.typeConceptId,
    this.address,
  });

  final int id;
  final String name;
  final String? code;
  final int? typeConceptId;
  final FullAddressOption? address;

  static PlaceDetail? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'] ?? map;
    if (data is! Map) return null;
    final item = Map<String, dynamic>.from(data);
    final id = item['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    final name = item['name']?.toString().trim();
    if (parsedId == null || name == null || name.isEmpty) return null;
    final typeRaw = item['typeConceptId'];
    final typeId = typeRaw is int
        ? typeRaw
        : typeRaw is num
            ? typeRaw.toInt()
            : int.tryParse(typeRaw?.toString() ?? '');
    return PlaceDetail(
      id: parsedId,
      name: name,
      code: item['code']?.toString(),
      typeConceptId: typeId,
      address: FullAddressOption.fromJson(item['address']),
    );
  }
}

/// Page `GET /api/v1/organizations/{id}/places`.
class OrganizationPlacesResult {
  const OrganizationPlacesResult({
    required this.items,
    this.total,
  });

  final List<SpatialUnitOption> items;
  final int? total;

  static OrganizationPlacesResult fromJson(Map<String, dynamic>? body) {
    if (body == null) {
      return const OrganizationPlacesResult(items: []);
    }
    final raw = body['data'] as List<dynamic>? ?? [];
    final items = raw
        .map(SpatialUnitOption.fromJson)
        .whereType<SpatialUnitOption>()
        .toList();
    final meta = body['meta'];
    int? total;
    if (meta is Map) {
      final t = meta['total'];
      if (t is int) {
        total = t;
      } else if (t is num) {
        total = t.toInt();
      }
    }
    return OrganizationPlacesResult(items: items, total: total);
  }
}
