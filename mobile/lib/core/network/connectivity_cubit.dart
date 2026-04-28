import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit() : super(true) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    final current = await Connectivity().checkConnectivity();
    emit(!current.contains(ConnectivityResult.none));
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      emit(!results.contains(ConnectivityResult.none));
    });
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
