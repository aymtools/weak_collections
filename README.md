# weak_collections

This package contains the classes:

* **WeakHashMap**
* **WeakHashSet**
* **WeakLinkedHashMap**
* **WeakLinkedHashSet**
* **MixedRefHashSet** (alias `MixedWeakHashSet`, `MixedHashSet`)
* **MixedRefLinkedHashSet** (alias `MixedWeakLinkedHashSet`, `MixedLinkedHashSet`)
* **MixedRefHashMap** (alias `MixedWeakHashMap`, `MixedHashMap`)
* **MixedRefLinkedHashMap** (alias `MixedWeakLinkedHashMap`, `MixedLinkedHashMap`)
* **WeakQueue**

## WeakHashMap

A WeakHashMap allows you to garbage collect its keys, and remove references to values after keys are
recycled.
This means that when the key is recycled, the value will also be recycled.

```dart
Object? o = Object();
Object o2 = Object();
WeakHashMap weakMap = WeakHashMap();
weakMap[o] = o2;
o = null;

// After garbage collection weakMap[o] will be removed.
print(weakMap.length); // print 0  
```

## WeakHashSet

WeakHashSet will automatically free objects stored in unreferenced.
This means that if an object has no other application, it will not exist in the WeakSet.

```dart
Object? o = Object();
WeakHashSet weakSet = WeakHashSet();
weakSet.add(o);
o = null;

// After garbage collection [o] will be removed.
print(weakSet.length); // print 0  
```

## MixedRefHashSet & MixedRefHashMap

`MixedRefHashSet` and `MixedRefHashMap` allow you to store elements or keys using a **mixed combination of weak and strong references** within the same collection.

You can explicitly specify whether an element or key is stored as weak or strong upon insertion:

```dart
final set = MixedRefHashSet<Object>();

Object? weakObj = Object();
Object? strongObj = Object();

set.addWeak(weakObj);     // Added as a weak reference (collected after GC when unreferenced)
set.addStrong(strongObj); // Added as a strong reference (remains in set after GC)

weakObj = null;
strongObj = null;

// After garbage collection, weakObj is removed while strongObj remains in the set.
```

Similarly for `MixedRefHashMap`:

```dart
final map = MixedRefHashMap<Object, String>();

Object? weakKey = Object();
Object? strongKey = Object();

map.putWeakKey(weakKey, 'weakValue');     // Key stored as weak reference
map.putStrongKey(strongKey, 'strongValue'); // Key stored as strong reference

weakKey = null;
strongKey = null;

// After garbage collection, weakKey entry is removed while strongKey entry remains.
```

## WeakQueue

WeakQueue will automatically release unreferenced objects in the queue.
which means that the queue object will not be automatically recycled and removed from the queue.

```dart
Object? o = Object();
WeakQueue weakQueue = WeakQueue();
weakQueue.add(o);
o = null;

// After garbage collection [o] will be removed.
print(weakQueue.length); // print 0  
```

## Usage

See [example](https://github.com/aymtools/weak_collections/blob/master/example/example.dart) for
detailed test
case.

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/weak_collections/issues):
