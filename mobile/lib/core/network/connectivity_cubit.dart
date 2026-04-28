import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityBannerState { online, offline, reconnecting }

class ConnectivityCubit extends Cubit<ConnectivityBannerState> {
  ConnectivityCubit() : super(ConnectivityBannerState.online) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    final current = await Connectivity().checkConnectivity();
    emit(current.contains(ConnectivityResult.none) ? ConnectivityBannerState.offline : ConnectivityBannerState.online);
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (!isOnline) {
        emit(ConnectivityBannerState.offline);
        return;
      }
      if (state == ConnectivityBannerState.offline) {
        emit(ConnectivityBannerState.reconnecting);
      }
      emit(ConnectivityBannerState.online);
    });
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
