import 'dart:math';

class TestObject {
  final String id;

  TestObject(this.id);

  @override
  String toString() => 'TestObject(id: $id)';
}

bool customEquals(TestObject a, TestObject b) => a.id == b.id;

int customHashCode(TestObject a) => a.id.hashCode;

final _aHashCode = identityHashCode('a');

/// 依然会存在一个 1/(bucket.length) 的概率触发 桶碰撞，所以还是有概率 在桶中找到
int customHashCodeNotAThenRandom(TestObject a) {
  if (a.id == 'a') return _aHashCode;
  int currentTime = DateTime.now().millisecondsSinceEpoch;
  int randomValue = Random().nextInt(1000000); // 随机数，确保变化
  final result = currentTime + randomValue;

  return result;
}

bool customIsValidKeyOnlyA(Object? a) => a is TestObject && a.id == 'a';

bool customIsValidKeyAdB(Object? a) =>
    a is TestObject && (a.id == 'a' || a.id == 'b');

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

class TestEqualsObject {
  final String id;

  TestEqualsObject(this.id);

  @override
  String toString() => 'TestEqualsObject(id: $id)';

  @override
  int get hashCode => Object.hash(id, TestEqualsObject);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestEqualsObject &&
          runtimeType == other.runtimeType &&
          id == other.id;
}
