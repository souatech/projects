import 'package:geocoding/geocoding.dart';

class AddressFormatter {
  static const String defaultFallback = 'Choisir une adresse';

  static String shortAddress(
    dynamic value, {
    Map<String, dynamic>? addressDetails,
    String fallback = defaultFallback,
  }) {
    final fromDetails = _fromAddressDetails(addressDetails);
    if (_isUsable(fromDetails)) {
      return fromDetails;
    }

    if (value is Placemark) {
      final fromPlacemark = _fromPlacemark(value);
      if (_isUsable(fromPlacemark)) {
        return fromPlacemark;
      }
      return fallback;
    }

    final raw = value?.toString();
    final fromText = _fromText(raw);
    return _isUsable(fromText) ? fromText : fallback;
  }

  static String fullAddressFromPlacemark(Placemark? place) {
    if (place == null) return '';
    final parts = <String>[];

    void add(String? value) {
      final cleaned = _cleanPart(value);
      if (cleaned.isNotEmpty &&
          !parts.any((part) => _samePart(part, cleaned))) {
        parts.add(cleaned);
      }
    }

    add(place.name);
    add(place.street);
    add(place.subLocality);
    add(place.locality);
    add(place.subAdministrativeArea);
    add(place.administrativeArea);
    add(place.postalCode);
    add(place.country);

    return parts.join(', ');
  }

  static String? countryCode(String? value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return null;
    if (normalized.length == 2 && RegExp(r'^[a-z]{2}$').hasMatch(normalized)) {
      return normalized;
    }

    const codes = {
      'senegal': 'sn',
      'sénégal': 'sn',
      'france': 'fr',
      'france metropolitaine': 'fr',
      'france métropolitaine': 'fr',
      'cote divoire': 'ci',
      'côte divoire': 'ci',
      'cote d ivoire': 'ci',
      'côte d ivoire': 'ci',
      'cote d’ivoire': 'ci',
      'côte d’ivoire': 'ci',
      'india': 'in',
      'inde': 'in',
    };
    return codes[normalized];
  }

  static String _fromAddressDetails(Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) return '';

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = _cleanPart(details[key]?.toString());
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final road = _compactRoad(
      pick([
        'road',
        'pedestrian',
        'footway',
        'path',
        'residential',
        'cycleway',
      ]),
    );
    final suburb = _compactNeighborhood(
      pick(['suburb', 'neighbourhood', 'neighborhood', 'quarter']),
    );
    final district = _compactNeighborhood(
      pick(['city_district', 'district', 'borough', 'municipality', 'county']),
    );
    final city = _compactNeighborhood(
      pick([
        'city',
        'town',
        'village',
        'municipality',
        'commune',
        'state_district',
        'county',
      ]),
    );

    if (road.isNotEmpty && city.isNotEmpty) return _join(road, city);
    if (suburb.isNotEmpty && city.isNotEmpty) return _join(suburb, city);
    if (district.isNotEmpty && city.isNotEmpty) return _join(district, city);
    if (city.isNotEmpty) return city;
    return _firstUsable([road, suburb, district]);
  }

  static String _fromPlacemark(Placemark place) {
    final road = _compactRoad(
      _firstUsable([place.thoroughfare, place.street, place.name]),
    );
    final suburb = _compactNeighborhood(
      _firstUsable([place.subLocality, place.subAdministrativeArea]),
    );
    final district = _compactNeighborhood(place.subAdministrativeArea);
    final city = _compactNeighborhood(
      _firstUsable([
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]),
    );

    if (road.isNotEmpty && city.isNotEmpty) return _join(road, city);
    if (suburb.isNotEmpty && city.isNotEmpty) return _join(suburb, city);
    if (district.isNotEmpty && city.isNotEmpty) return _join(district, city);
    if (city.isNotEmpty) return city;
    return _firstUsable([road, suburb, district, place.country]);
  }

  static String _fromText(String? raw) {
    final cleaned =
        (raw ?? '')
            .replaceAll('\n', ', ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    if (!_isUsable(cleaned)) return '';

    final parts =
        cleaned
            .split(',')
            .map(_cleanPart)
            .where((part) => part.isNotEmpty)
            .where((part) => !_looksCountry(part))
            .where((part) => !_looksAdministrative(part))
            .toList();
    if (parts.isEmpty) return '';

    final first = _compactRoad(parts.first);
    final city = _pickCityLike(parts.skip(1).toList());
    if (first.isNotEmpty && city.isNotEmpty) {
      return _join(first, city);
    }
    if (first.isNotEmpty) return first;
    return city;
  }

  static String _pickCityLike(List<String> parts) {
    for (final part in parts) {
      final cleaned = _compactNeighborhood(part);
      if (cleaned.isNotEmpty && !_looksPostalCode(cleaned)) {
        return cleaned;
      }
    }
    return '';
  }

  static String _compactRoad(String? value) {
    var cleaned = _cleanPart(value);
    cleaned = cleaned.replaceFirst(RegExp(r'^\d+\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^\d+[A-Za-z]?\s*,?\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\d+$'), '');
    return cleaned.trim();
  }

  static String _compactNeighborhood(String? value) {
    var cleaned = _cleanPart(value);
    cleaned = cleaned.replaceFirst(RegExp(r'^\d{4,6}\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\d+$'), '');
    return cleaned.trim();
  }

  static String _cleanPart(String? value) {
    return (value ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '')
        .trim();
  }

  static String _join(String first, String second) {
    if (_samePart(first, second)) return first;
    return '$first, $second';
  }

  static String _firstUsable(List<String?> values) {
    for (final value in values) {
      final cleaned = _cleanPart(value);
      if (_isUsable(cleaned) && !_looksCountry(cleaned)) {
        return cleaned;
      }
    }
    return '';
  }

  static bool _isUsable(String? value) {
    final cleaned = _cleanPart(value);
    if (cleaned.isEmpty) return false;
    final normalized = _normalize(cleaned);
    return normalized != 'unknown location' &&
        normalized != 'unknown' &&
        normalized != 'null' &&
        normalized != '0 0' &&
        !_looksCoordinates(cleaned) &&
        normalized != 'adresse non renseignee' &&
        normalized != 'adresse non renseignée';
  }

  static bool _samePart(String left, String right) {
    return _normalize(left) == _normalize(right);
  }

  static bool _looksPostalCode(String value) {
    return RegExp(r'^\d{4,6}$').hasMatch(value.trim());
  }

  static bool _looksCoordinates(String value) {
    return RegExp(
      r'^-?\d{1,3}(\.\d+)?\s*,\s*-?\d{1,3}(\.\d+)?$',
    ).hasMatch(value.trim());
  }

  static bool _looksAdministrative(String value) {
    final normalized = _normalize(value);
    return _looksPostalCode(normalized) ||
        normalized.contains('departement') ||
        normalized.contains('département') ||
        normalized.contains('region') ||
        normalized.contains('région') ||
        normalized.contains('arrondissement') ||
        normalized.contains('province') ||
        normalized.contains('county');
  }

  static bool _looksCountry(String value) {
    return countryCode(value) != null;
  }

  static String _normalize(String? value) {
    return _cleanPart(value)
        .toLowerCase()
        .replaceAll("'", ' ')
        .replaceAll('’', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
