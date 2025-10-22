import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  String? _cachedLocation;
  DateTime? _lastLocationUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Obtient la localisation actuelle avec cache
  Future<String> getCurrentLocationName() async {
    // Vérifier le cache
    if (_cachedLocation != null && 
        _lastLocationUpdate != null && 
        DateTime.now().difference(_lastLocationUpdate!) < _cacheExpiry) {
      return _cachedLocation!;
    }

    try {
      // Vérifier les permissions
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        developer.log('Permissions de localisation refusées', name: 'LocationService');
        return 'Côte d\'Ivoire';
      }

      // Obtenir la position avec timeout et fallback
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Changé de high à medium pour plus de compatibilité
          timeLimit: Duration(seconds: 5), // Réduit de 10 à 5 secondes
        ),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          developer.log('Timeout lors de la récupération de la position', name: 'LocationService');
          throw Exception('Timeout géolocalisation');
        },
      );

      // Convertir en adresse avec timeout
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('Timeout lors du geocoding', name: 'LocationService');
          return []; // Retourner liste vide en cas de timeout
        },
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        String locationName = _formatLocationName(placemark);
        
        // Mettre en cache
        _cachedLocation = locationName;
        _lastLocationUpdate = DateTime.now();
        
        developer.log('Localisation obtenue: $locationName', name: 'LocationService');
        return locationName;
      }
    } on TimeoutException catch (e) {
      developer.log('Timeout géolocalisation: $e', name: 'LocationService');
    } on PlatformException catch (e) {
      // Erreur spécifique aux services Google Play ou permissions
      developer.log('Erreur plateforme géolocalisation: ${e.code} - ${e.message}', name: 'LocationService');
      
      // Si c'est une erreur IO_ERROR ou UNAVAILABLE, utiliser le fallback silencieusement
      if (e.code == 'IO_ERROR' || e.code == 'UNAVAILABLE') {
        developer.log('Services de localisation non disponibles, utilisation du fallback', name: 'LocationService');
      }
    } catch (e) {
      developer.log('Erreur géolocalisation générale: $e', name: 'LocationService');
    }

    // Fallback par défaut - retourner sans erreur
    return 'Côte d\'Ivoire';
  }

  /// Formate le nom de la localisation de manière appropriée
  String _formatLocationName(Placemark placemark) {
    // Priorité: Ville -> Région/État -> Pays
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      // Si c'est une ville connue en Côte d'Ivoire
      final city = placemark.locality!;
      if (_isIvorianCity(city)) {
        return city;
      }
    }

    if (placemark.subAdministrativeArea != null && 
        placemark.subAdministrativeArea!.isNotEmpty) {
      return placemark.subAdministrativeArea!;
    }

    if (placemark.administrativeArea != null && 
        placemark.administrativeArea!.isNotEmpty) {
      return placemark.administrativeArea!;
    }

    if (placemark.country != null && placemark.country!.isNotEmpty) {
      return placemark.country!;
    }

    return 'Localisation inconnue';
  }

  /// Vérifie si c'est une ville ivoirienne connue
  bool _isIvorianCity(String city) {
    final ivorianCities = [
      'Abidjan', 'Bouaké', 'Daloa', 'Yamoussoukro', 'San-Pédro',
      'Korhogo', 'Man', 'Divo', 'Gagnoa', 'Abengourou', 'Agnibilékrou',
      'Anyama', 'Dabou', 'Grand-Bassam', 'Jacqueville', 'Tiassalé',
      'Issia', 'Soubré', 'Sassandra', 'Tabou', 'Danané', 'Duékoué',
      'Guiglo', 'Bangolo', 'Biankouma', 'Odienné', 'Boundiali',
      'Ferkessédougou', 'Katiola', 'Séguéla', 'Touba', 'Zuénoula'
    ];

    return ivorianCities.any((ivoCity) => 
      city.toLowerCase().contains(ivoCity.toLowerCase()) ||
      ivoCity.toLowerCase().contains(city.toLowerCase())
    );
  }

  /// Gère les permissions de géolocalisation
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de géolocalisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtient la position précise pour des besoins spécifiques
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      developer.log('Erreur position: $e', name: 'LocationService');
      return null;
    }
  }

  /// Efface le cache de localisation
  void clearLocationCache() {
    _cachedLocation = null;
    _lastLocationUpdate = null;
  }

  /// Demande explicitement les permissions de localisation
  Future<bool> requestLocationPermissions() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      developer.log('Erreur permissions: $e', name: 'LocationService');
      return false;
    }
  }
}