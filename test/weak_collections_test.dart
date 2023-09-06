import 'package:weak_collections/weak_collections.dart';

void main() {
  void main() {
    Object? o = Object();
    Object o2 = Object();
    WeakReference wr = WeakReference(o);
    Finalizer _finalizer = Finalizer((d) => print('_finalizer ${d == o2}'));
    _finalizer.attach(o, o2);

    Object? o3 = Object();
    _finalizer.attach(o3, o2);

    Object? o4 = Object();
    _finalizer.attach(o4, o2);
    _finalizer.detach(o2);
    o = null;
    List lis = [];
    _finalizer.detach(o2);
    _finalizer.detach(o2);

    o3 = null;

    for (int i = 0; i < 20; i++) {
      print(wr.target == null);
      lis = List.filled(1020000, () => i);
      if (i == 9) o4 = null;
    }
    Future.value('').then((_) {
      print(wr.target == null);
    }).then((_) {
      print(wr.target == null);
    }).then((_) {
      print(wr.target == null);
    }).then((_) {
      print(wr.target == null);
    }).then((_) {
      print(wr.target == null);
    }).then((_) {
      print(wr.target == null);
    }).then((_) {
      print(wr.target == null);
    });
    o = null;
  }
}
