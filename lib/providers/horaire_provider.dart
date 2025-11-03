import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/horaire_model.dart';
import '../services/horaire_service.dart';

class HoraireProvider with ChangeNotifier {
  final HoraireService _horaireService = HoraireService();
  
  List<Horaire> _horaires = [];
  Map<String, List<Horaire>> _horairesGrouped = {};
  bool _isLoading = false;
  String? _error;
  Timer? _autoRefreshTimer;
  
  // Durée de rafraîchissement automatique (90 secondes pour éviter le rate limiting)
  static const Duration autoRefreshDuration = Duration(seconds: 90);

  List<Horaire> get horaires => _horaires;
  Map<String, List<Horaire>> get horairesGrouped => _horairesGrouped;
  bool get isLoading => _isLoading;
  String? get error => _error;

  HoraireProvider() {
    // Charger les horaires au démarrage
    fetchTodayHoraires();
    // Démarrer le rafraîchissement automatique
    startAutoRefresh();
  }

  /// Démarrer le rafraîchissement automatique
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(autoRefreshDuration, (_) {
      fetchTodayHoraires(silent: true); // Silent = pas de loading indicator
    });
  }

  /// Arrêter le rafraîchissement automatique
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  /// Récupérer tous les horaires
  Future<void> fetchAllHoraires({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _horaires = await _horaireService.fetchAllHoraires();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur lors du chargement des horaires: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Récupérer les horaires par gare
  Future<void> fetchHorairesByGare(int gareId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _horaires = await _horaireService.fetchHorairesByGare(gareId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur lors du chargement des horaires: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Récupérer les horaires par appareil
  Future<void> fetchHorairesByAppareil(String appareil, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _horaires = await _horaireService.fetchHorairesByAppareil(appareil);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur lors du chargement des horaires: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Récupérer les horaires d'aujourd'hui (groupés par gare)
  Future<void> fetchTodayHoraires({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _horairesGrouped = await _horaireService.fetchTodayHoraires();
      
      // Aplatir pour avoir aussi une liste simple
      _horaires = [];
      _horairesGrouped.forEach((gare, horaires) {
        _horaires.addAll(horaires);
      });
      
      _error = null;
      notifyListeners(); // Toujours notifier pour les mises à jour silencieuses
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur lors du chargement des horaires: $e');
      if (!silent) {
        notifyListeners();
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
    }
  }

  /// Rafraîchir manuellement
  Future<void> refresh() async {
    return fetchTodayHoraires();
  }

  /// Obtenir les horaires d'une gare spécifique depuis les données groupées
  List<Horaire> getHorairesByGareName(String gareName) {
    return _horairesGrouped[gareName] ?? [];
  }

  /// Obtenir tous les noms de gares
  List<String> get gareNames => _horairesGrouped.keys.toList();

  /// Obtenir les horaires filtrés par statut
  List<Horaire> getHorairesByStatus(String status) {
    return _horaires.where((h) => h.statut == status).toList();
  }

  /// Obtenir les prochains départs (horaires actifs, triés par heure)
  List<Horaire> get prochainDeparts {
    return _horaires
        .where((h) => h.actif && h.statut != 'termine')
        .toList()
      ..sort((a, b) => a.heure.compareTo(b.heure));
  }

  /// Obtenir les horaires en embarquement
  List<Horaire> get horairesEnEmbarquement {
    return _horaires.where((h) => h.statut == 'embarquement').toList();
  }

  /// Obtenir les horaires à l'heure
  List<Horaire> get horairesALheure {
    return _horaires.where((h) => h.statut == 'a_l_heure').toList();
  }

  /// Obtenir les horaires terminés
  List<Horaire> get horairesTermines {
    return _horaires.where((h) => h.statut == 'termine').toList();
  }
}
