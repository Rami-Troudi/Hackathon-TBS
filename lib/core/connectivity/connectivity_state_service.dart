import 'dart:async';

import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';

enum AppConnectivityState {
  online,
  degraded,
  offline,
}

extension AppConnectivityStateX on AppConnectivityState {
  static AppConnectivityState fromRaw(String? raw) => switch (raw) {
        'degraded' => AppConnectivityState.degraded,
        'offline' => AppConnectivityState.offline,
        _ => AppConnectivityState.online,
      };
}

abstract class ConnectivityStateService {
  AppConnectivityState get currentState;
  Stream<AppConnectivityState> watch();
  Future<void> initialize();
  Future<void> setState(AppConnectivityState state);
  void dispose();
}

class InMemoryConnectivityStateService implements ConnectivityStateService {
  InMemoryConnectivityStateService({
    AppConnectivityState initialState = AppConnectivityState.online,
  }) : _currentState = initialState;

  final StreamController<AppConnectivityState> _controller =
      StreamController<AppConnectivityState>.broadcast();
  AppConnectivityState _currentState;

  @override
  AppConnectivityState get currentState => _currentState;

  @override
  Future<void> initialize() async {
    _controller.add(_currentState);
  }

  @override
  Future<void> setState(AppConnectivityState state) async {
    if (_currentState == state) return;
    _currentState = state;
    _controller.add(state);
  }

  @override
  Stream<AppConnectivityState> watch() async* {
    yield _currentState;
    yield* _controller.stream;
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class LocalConnectivityStateService implements ConnectivityStateService {
  LocalConnectivityStateService({
    required this.storage,
    required this.logger,
  });

  final StorageService storage;
  final AppLogger logger;
  final StreamController<AppConnectivityState> _controller =
      StreamController<AppConnectivityState>.broadcast();

  AppConnectivityState _currentState = AppConnectivityState.online;

  @override
  AppConnectivityState get currentState => _currentState;

  @override
  Future<void> initialize() async {
    final raw = storage.getString(StorageKeys.connectivityState);
    _currentState = AppConnectivityStateX.fromRaw(raw);
    _controller.add(_currentState);
    logger.info('Connectivity mode initialized: ${_currentState.name}');
  }

  @override
  Future<void> setState(AppConnectivityState state) async {
    if (_currentState == state) return;
    _currentState = state;
    await storage.setString(StorageKeys.connectivityState, state.name);
    _controller.add(state);
    logger.info('Connectivity mode set to ${state.name}');
  }

  @override
  Stream<AppConnectivityState> watch() async* {
    yield _currentState;
    yield* _controller.stream;
  }

  @override
  void dispose() {
    _controller.close();
  }
}
