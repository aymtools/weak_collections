import 'package:weak_collections/src/map/hash_map.dart';
import 'package:weak_collections/src/set/hash_set.dart';

@Deprecated('use WeakHashMap')
typedef WeakMap<K extends Object, V> = WeakHashMap<K, V>;

@Deprecated('use WeakHashSet')
typedef WeakSet<E extends Object> = WeakHashSet<E>;
