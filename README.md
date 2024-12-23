# weak_collections

This package contains the classes:

* **WeakHashMap**
* **WeakHashSet**

## WeakHashMap

A WeakHashMap allows you to garbage collect its keys, and remove references to values after keys are
recycled.
This means that when the key is recycled, the value will also be recycled.

```
Object? o = Object();
Object o2 = Object();
WeakHashMap weakMap = WeakHashMap();
weakMap[o] =o2;
o = null;

// After garbage collection weakMap[o] will be removed.
print(weakMap.length); // print 0  

```

## WeakHashSet

WeakHashSet will automatically free objects stored in unreferenced.
This means that if an object has no other application, it will not exist in the WeakSet.

```
Object? o = Object();
WeakHashSet weakSet = WeakHashSet();
weakSet.add(o);
o = null;

// After garbage collection [o] will be removed.
print(weakSet.length); // print 0  
```

## Usage

See [example](https://github.com/aymtools/weak_collections/blob/master/example/example.dart) for
detailed test
case.

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/weak_collections/issues):
