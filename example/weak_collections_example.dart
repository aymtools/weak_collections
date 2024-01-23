import 'package:weak_collections/weak_collections.dart' as weak;

void main() {
  Object? o = Object();
  Object o2 = Object();
  weak.WeakMap weakMap = weak.WeakMap();
  weak.WeakSet weakSet = weak.WeakSet();
  weakMap[o] = o2;
  weakSet.add(o);
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
