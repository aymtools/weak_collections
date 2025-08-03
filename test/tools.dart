class TestVal {
  final String debugName;

  TestVal(this.debugName);

  @override
  String toString() {
    return 'TestVal($debugName)';
  }
}

class SubVal extends TestVal {
  SubVal(super.debugName);

  @override
  String toString() {
    return 'SubVal($debugName)';
  }
}

class Test2Val {
  final String debugName;

  Test2Val(this.debugName);

  @override
  String toString() {
    return 'Test2Val($debugName)';
  }
}
