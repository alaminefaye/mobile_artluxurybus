import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';

class LocationState {
  final String locationName;
  final bool isLoading;
  final bool hasPermission;
  final String? error;

  const LocationState({
    required this.locationName,
    this.isLoading = false,
    this.hasPermission = true,
    this.error,
  });

  LocationState copyWith({
    String? locationName,
    bool? isLoading,
    bool? hasPermission,
    String? error,
  }) {
    return LocationState(
      locationName: locationName ?? this.locationName,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(
    const LocationState(locationName: 'Côte d\'Ivoire')
  ) {
    // Charger la localisation automatiquement au démarrage
    loadLocation();
  }

  /// Charge la localisation actuelle
  Future<void> loadLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final locationName = await _locationService.getCurrentLocationName();
      state = state.copyWith(
        locationName: locationName,
        isLoading: false,
        hasPermission: locationName != 'Localisation non disponible',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible d\'obtenir la localisation',
        locationName: 'Côte d\'Ivoire', // Fallback
      );
    }
  }

  /// Actualise la localisation
  Future<void> refreshLocation() async {
    _locationService.clearLocationCache();
    await loadLocation();
  }

  /// Demande les permissions de localisation
  Future<void> requestPermissions() async {
    state = state.copyWith(isLoading: true);
    
    final granted = await _locationService.requestLocationPermissions();
    if (granted) {
      await loadLocation();
    } else {
      state = state.copyWith(
        isLoading: false,
        hasPermission: false,
        error: 'Permissions de localisation refusées',
      );
    }
  }
}

// Providers
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});