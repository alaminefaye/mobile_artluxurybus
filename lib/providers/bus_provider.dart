import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bus_models.dart';
import '../services/bus_api_service.dart';

// ===== Service Provider =====
final busApiServiceProvider = Provider<BusApiService>((ref) {
  return BusApiService();
});

// ===== Dashboard Provider =====
final busDashboardProvider = FutureProvider<BusDashboard>((ref) async {
  final service = ref.read(busApiServiceProvider);
  return await service.getDashboard();
});

// ===== Bus List State =====
class BusListState {
  final List<Bus> buses;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int total;
  final String? statusFilter;
  final String? searchQuery;

  BusListState({
    this.buses = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.statusFilter,
    this.searchQuery,
  });

  BusListState copyWith({
    List<Bus>? buses,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? total,
    String? statusFilter,
    String? searchQuery,
    bool clearError = false,
  }) {
    return BusListState(
      buses: buses ?? this.buses,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ===== Bus List Notifier =====
class BusListNotifier extends StateNotifier<BusListState> {
  final BusApiService _service;

  BusListNotifier(this._service) : super(BusListState());

  Future<void> loadBuses({
    int page = 1,
    String? status,
    String? search,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getBuses(
        page: page,
        status: status,
        search: search,
      );

      state = BusListState(
        buses: response.data,
        isLoading: false,
        currentPage: response.currentPage,
        totalPages: response.lastPage,
        total: response.total,
        statusFilter: status,
        searchQuery: search,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshBuses() async {
    await loadBuses(
      page: 1,
      status: state.statusFilter,
      search: state.searchQuery,
    );
  }

  Future<void> loadNextPage() async {
    if (state.currentPage < state.totalPages && !state.isLoading) {
      await loadBuses(
        page: state.currentPage + 1,
        status: state.statusFilter,
        search: state.searchQuery,
      );
    }
  }

  void setStatusFilter(String? status) {
    loadBuses(page: 1, status: status, search: state.searchQuery);
  }

  void setSearchQuery(String? query) {
    loadBuses(page: 1, status: state.statusFilter, search: query);
  }

  void clearFilters() {
    loadBuses(page: 1);
  }
}

final busListProvider = StateNotifierProvider<BusListNotifier, BusListState>((ref) {
  final service = ref.read(busApiServiceProvider);
  return BusListNotifier(service);
});

// ===== Bus Details Provider =====
final busDetailsProvider = FutureProvider.family<Bus, int>((ref, busId) async {
  final service = ref.read(busApiServiceProvider);
  return await service.getBusDetails(busId);
});

// ===== Maintenance Provider =====
final maintenanceListProvider = FutureProvider.family<PaginatedResponse<MaintenanceRecord>, int>(
  (ref, busId) async {
    final service = ref.read(busApiServiceProvider);
    return await service.getMaintenances(busId);
  },
);

// ===== Fuel History Provider =====
final fuelHistoryProvider = FutureProvider.family<PaginatedResponse<FuelRecord>, int>(
  (ref, busId) async {
    final service = ref.read(busApiServiceProvider);
    return await service.getFuelHistory(busId);
  },
);

// ===== Fuel Stats Provider =====
final fuelStatsProvider = FutureProvider.family<FuelStats, int>((ref, busId) async {
  final service = ref.read(busApiServiceProvider);
  return await service.getFuelStats(busId);
});

// ===== Technical Visits Provider =====
final technicalVisitsProvider = FutureProvider.family<PaginatedResponse<TechnicalVisit>, int>(
  (ref, busId) async {
    final service = ref.read(busApiServiceProvider);
    return await service.getTechnicalVisits(busId);
  },
);

// ===== Insurance History Provider =====
final insuranceHistoryProvider = FutureProvider.family<PaginatedResponse<InsuranceRecord>, int>(
  (ref, busId) async {
    final service = ref.read(busApiServiceProvider);
    return await service.getInsuranceHistory(busId);
  },
);

// ===== Patents Provider =====
final patentsProvider = FutureProvider.family<PaginatedResponse<Patent>, int>(
  (ref, busId) async {
    final service = ref.read(busApiServiceProvider);
    return await service.getPatents(busId);
  },
);

// ===== Breakdowns State & Notifier =====
class BreakdownsState {
  final List<BusBreakdown> breakdowns;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;

  BreakdownsState({
    this.breakdowns = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  BreakdownsState copyWith({
    List<BusBreakdown>? breakdowns,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool clearError = false,
  }) {
    return BreakdownsState(
      breakdowns: breakdowns ?? this.breakdowns,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class BreakdownsNotifier extends StateNotifier<BreakdownsState> {
  final BusApiService _service;
  final int busId;

  BreakdownsNotifier(this._service, this.busId) : super(BreakdownsState()) {
    loadBreakdowns();
  }

  Future<void> loadBreakdowns({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getBreakdowns(busId, page: page);
      state = BreakdownsState(
        breakdowns: response.data,
        isLoading: false,
        currentPage: response.currentPage,
        totalPages: response.lastPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addBreakdown({
    required String description,
    required DateTime breakdownDate,
    required String severity,
    required String status,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.addBreakdown(
        busId: busId,
        description: description,
        breakdownDate: breakdownDate,
        severity: severity,
        status: status,
        notes: notes,
      );

      // Recharger la liste après ajout
      await loadBreakdowns();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadBreakdowns(page: 1);
  }
}

final breakdownsProvider = StateNotifierProvider.family<BreakdownsNotifier, BreakdownsState, int>(
  (ref, busId) {
    final service = ref.read(busApiServiceProvider);
    return BreakdownsNotifier(service, busId);
  },
);

// ===== Vidanges State & Notifier =====
class VidangesState {
  final List<BusVidange> vidanges;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;

  VidangesState({
    this.vidanges = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  VidangesState copyWith({
    List<BusVidange>? vidanges,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool clearError = false,
  }) {
    return VidangesState(
      vidanges: vidanges ?? this.vidanges,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class VidangesNotifier extends StateNotifier<VidangesState> {
  final BusApiService _service;
  final int busId;

  VidangesNotifier(this._service, this.busId) : super(VidangesState()) {
    loadVidanges();
  }

  Future<void> loadVidanges({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getVidanges(busId, page: page);
      state = VidangesState(
        vidanges: response.data,
        isLoading: false,
        currentPage: response.currentPage,
        totalPages: response.lastPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> scheduleVidange({
    required DateTime plannedDate,
    required String type,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.scheduleVidange(
        busId: busId,
        plannedDate: plannedDate,
        type: type,
        notes: notes,
      );

      // Recharger la liste après planification
      await loadVidanges();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> completeVidange({
    required int vidangeId,
    required DateTime completionDate,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.completeVidange(
        busId: busId,
        vidangeId: vidangeId,
        completionDate: completionDate,
        notes: notes,
      );

      // Recharger la liste après marquage
      await loadVidanges();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadVidanges(page: 1);
  }
}

final vidangesProvider = StateNotifierProvider.family<VidangesNotifier, VidangesState, int>(
  (ref, busId) {
    final service = ref.read(busApiServiceProvider);
    return VidangesNotifier(service, busId);
  },
);
