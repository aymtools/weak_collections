import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:vm_service/vm_service.dart' hide Isolate;
import 'package:vm_service/vm_service_io.dart';

class VmServiceTool {
  late VmService _vmService;

  VmServiceTool._();

  static final VmServiceTool _instance = VmServiceTool._();

  static VmServiceTool get instance => _instance;

  bool _canUseVMGc = false;

  Future<bool> get canUseVMGc async {
    await _init;
    return _canUseVMGc;
  }

  late final Future<void> _init = () async {
    final serverUri = (await Service.getInfo()).serverUri;
    if (serverUri != null) {
      final vmService = await vmServiceConnectUri(_toWebSocketUri(serverUri));
      _vmService = vmService;
      _canUseVMGc = true;
    }
  }();

  void dispose() {
    if (_canUseVMGc) {
      _vmService.dispose();
    }
  }

  String _toWebSocketUri(Uri uri) {
    final pathSegments = [...uri.pathSegments, 'ws'];
    return uri.replace(scheme: 'ws', pathSegments: pathSegments).toString();
  }

  Future<int?> gc({bool doGc = true}) async {
    await _init;
    if (!_canUseVMGc) {
      throw Exception(
          'Run test with: dart test --enable-vm-service -p vm --chain-stack-traces');
    }

    final isolateId = Service.getIsolateID(Isolate.current)!;
    final profile = await _vmService.getAllocationProfile(isolateId, gc: doGc);
    return Future.value(profile.memoryUsage?.heapUsage);
  }
}

Future<void> _waitVMGC() async {
  await VmServiceTool.instance.gc();
  return;
}

Future<void> _waitGC(Object check) async {
  if (await VmServiceTool.instance.canUseVMGc) {
    return Future.delayed(Duration(milliseconds: 100)).then((_) => _waitVMGC());
  }
  Completer<void> finalizerCompleter = Completer();
  void call() async {
    // 等待执行完 相关的 finalizer
    await Future.delayed(Duration.zero);
    finalizerCompleter.complete();
  }

  Finalizer<int> finalizer = Finalizer((_) => call());
  finalizer.attach(check, 1);
  return finalizerCompleter.future;
}

Future<void> _waitGCThen(FutureOr<void> Function() action, {Object? check}) {
  check ??= Object();
  final future = _waitGC(check).then((_) async {
    await action();
  });
  check = null;
  return future;
}

List<Future> _futures = [];

void afterGC(FutureOr<void> Function() action, {Object? check}) {
  _futures.add(_waitGCThen(action, check: check));
}

Future<void> tearDownWaitAllGC() async {
  while (_futures.isNotEmpty) {
    final fs = [..._futures];
    _futures.clear();
    await Future.wait(fs);
  }
}
