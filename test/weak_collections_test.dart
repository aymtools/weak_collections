void main() {
  Object? o = Object();
  Object o2 = Object();
  WeakReference wr = WeakReference(o);
  Finalizer finalizer = Finalizer((d) => print('_finalizer ${d == o2}'));
  finalizer.attach(o, o2);

  Object? o3 = Object();
  finalizer.attach(o3, o2);

  Object? o4 = Object();
  finalizer.attach(o4, o2);
  finalizer.detach(o2);
  o = null;
  List lis = [];
  finalizer.detach(o2);
  finalizer.detach(o2);

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
  lis.length;
  o = null;
}
