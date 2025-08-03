import 'package:weak_collections/weak_collections.dart';

void main() {
  Object? o = Object();
  Object o2 = Object();
  WeakHashMap weakMap = WeakHashMap();
  WeakHashSet weakSet = WeakHashSet();
  WeakQueue weakQueue = WeakQueue();
  weakMap[o] = o2;
  weakSet.add(o);
  weakQueue.add(o);
  o = null;
  List lis = [];
  Future(() => '').then((_) {
    lis = List.filled(1020000, () => Object());
    print(weakMap.length);
    Future(() => '').then((_) {
      lis = List.filled(1020000, () => Object());
      print(weakMap.length);
      Future(() => '').then((_) {
        lis = List.filled(1020000, () => Object());
        print(weakMap.length);
        Future(() => '').then((_) {
          for (int i = 0; i < 100; i++) {
            lis = List.filled(1020000, () => Object());
          }
          print(weakMap.length);
          Future(() => '').then((_) {
            lis = List.filled(1020000, () => Object());
            print(weakMap.length);
            Future(() => '').then((_) {
              lis = List.filled(1020000, () => Object());
              print(weakMap.length);
              Future(() => '').then((_) {
                lis = List.filled(1020000, () => Object());
                print(weakMap.length);
                Future(() => '').then((_) {
                  lis = List.filled(1020000, () => Object());
                  print(weakMap.length);
                  Future(() => '').then((_) {
                    lis = List.filled(1020000, () => Object());
                    print(weakMap.length);
                    Future(() => '').then((_) {
                      lis = List.filled(1020000, () => Object());
                      print(weakMap.length);
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
  });
  lis.length;
}
