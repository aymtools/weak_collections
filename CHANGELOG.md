## 1.6.1

* Fix: WeakHashMap.custom remove did not return the removed value

## 1.6.0

* Added WeakLinkedHashMap and WeakLinkedHashSet.

## 1.5.1

* Use identical to compare entries when executing expungeStale.

## 1.5.0

* A unified weak-reference management utility for WeakHashMap and WeakHashSet.

## 1.4.0

* WeakHashMap,WeakHashSet Add custom constructor for configurable isValidKey, hashCode and equals

## 1.3.3

* Use WeakReference for HashEntry management

## 1.3.2

* Optimize the creation of Finalizer during clear.

## 1.3.1

* Fixed the bug in the put method of WeakHashMap..

## 1.3.0

* Add WeakQueue.

## 1.2.2

* Add topics to improve searchability.

## 1.2.1

* Fix remove bug of WeakHashSet

## 1.2.0+1

* Compatibility mode export of WeakMap WeakSet

## 1.2.0

* To ensure reasonable naming, WeakMap has been renamed to WeakHashMap, and WeakSet has been renamed
  to WeakHashSet.

## 1.1.0

* In WeakSet, operations on null will directly return without processing.

## 1.0.1

* In WeakMap, the operation of `[]=null` is treated as remove.

## 1.0.0

* Initial implementation of WeakMap and WeakSet completed.