/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



public class CustomMapItem<K, V> <: Hashable & ToString where K <: Hashable & ToString & Equatable<K>, V <: ToString & Equatable<V> {
    
    public var insertTime: Int64

    public CustomMapItem(public var k: K, public var v: V) {
        this.insertTime = DateTime.now().nanosecond
    }
    
    public func hashCode(): Int64 {
        Utils.hashCodeWrite(k.hashCode(), reset: true)
        Utils.hashCodeWrite(k.hashCode())
        Utils.hashCodeFinish()
    }

    public func toString(): String {
        return "k : ${k} v: ${v}"
    }
}

public open class CustomMap<K, V> <: ToString & Equatable<CustomMap<K, V>> where K <: Hashable & ToString & Equatable<K>, V <: ToString & Equatable<V> {
    public var list: ArrayList<CustomMapItem<K, V>> = ArrayList<CustomMapItem<K, V>>()

    public func size(): Int64 {
        return list.size
    }

    public func isEmpty(): Bool {
        return list.isEmpty()
    }

    public func getIterator(): Iterator<CustomMapItem<K, V>> {
        return list.iterator()
    }

    public open func put(k: K, v: V): Option<V> {
        var old: Option<V> = None
        for(i in 0 .. list.size) {
            let l: CustomMapItem<K, V> = list[i]
            if(l.k == k) {
                old = Some(l.v)
            }
        }
        list.removeIf({t =>
            t.k == k
        })

        list.append(CustomMapItem(k, v))

        return old
    }

    public open func clear() {
        list.clear()
    }

    public open func putAll(map: CustomMap<K, V>): Unit {
        for(i in 0 .. map.list.size) {
            let l: CustomMapItem<K, V> = map.list[i]
            list.removeIf({t =>
                t.k == l.k
            })
        }

        list.appendAll(map.list)
    }

    public open func removeAt(index: Int64): V {
        return list.remove(index).v
    }

    public open func remove(k: K): Option<V> {
        var i = 0
        while(i < list.size) {
            if(list[i].k == k) {
                return Some(removeAt(i))
            }
            i++
        }
        return None
    }

    public open func valueAt(index: Int64): V {
        return list[index].v;
    }

    public open func keyAt(index: Int64): K {
        return list[index].k;
    }

    public func containsKey(k: K): Bool {
        for(i in 0 .. list.size) {
            let o: CustomMapItem<K, V> = list[i]
            if(o.k == k) {
                return true
            }
        }
        return false
    }

    public func get(k: K): Option<V> {
        for(i in 0 .. list.size) {
            let o: CustomMapItem<K, V> = list[i]
            if(o.k == k) {
                return Some(o.v)
            }
        }
        return None
    }

    public func hashCode(): Int64 {
        return Utils.hashCode<CustomMapItem<K, V>>(list.toArray())
    }

    public func toString(): String {
        var s = StringBuilder()
        for(i in 0 .. list.size) {
            let l: CustomMapItem<K, V> = list[i]
            s.append(l)
            s.append('\n')
        }
        return s.toString()
    }

    public operator func ==(other: CustomMap<K, V>): Bool {
        if(list.size != other.list.size){
            return false
        }
        for(i in 0 .. this.list.size) {
            let l: CustomMapItem<K, V> = list[i]
            let otherValue:Option<V> = other.get(l.k)
            if(otherValue.isNone()){
                return false
            }
            var theirs: V = otherValue.getOrThrow()
            if (l.v != theirs) {
                return false;
            }
        }
        return true
    }

    public operator func !=(other: CustomMap<K, V>): Bool {
        for(i in 0 .. this.list.size) {
            let l: CustomMapItem<K, V> = list[i]
            let otherValue:Option<V> = other.get(l.k)
             if(otherValue.isNone()){
                return true
            }
            var theirs: V = otherValue.getOrThrow()
            if (l.v == theirs) {
                return false;
            }
        }
        return true
    }
    
}

public class CachedHashCodeArrayMap<K, V> <: CustomMap<K, V> where K <: Hashable & ToString & Equatable<K>, V <: ToString & Equatable<V> {
    private var hashCodeInt: Int64 = 0

    public override func clear() {
        super.clear()
    }

    public override func put(k: K, v: V): Option<V> {
        hashCodeInt = 0
        super.put(k, v)
    }

    public override func putAll(map: CustomMap<K, V>): Unit {
        hashCodeInt = 0
        super.putAll(map)
    }

    public override func removeAt(index: Int64): V {
        hashCodeInt = 0
        return super.removeAt(index)
    }

}
