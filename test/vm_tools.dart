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
      throw Exception('Run test with: dart test --enable-vm-service');
    }

    final isolateId = Service.getIsolateID(Isolate.current)!;
    final profile = await _vmService.getAllocationProfile(isolateId, gc: doGc);
    return Future.value(profile.memoryUsage?.heapUsage);
  }
}
