/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public interface Poolable {
  func offer(): Unit;
}

public class Queue<T> {
  private let list: ArrayList<T>
  private let size: Int64
  public init(size: Int64) {
    list = ArrayList<T>()
    this.size = size
  }

  public func poll(): Option<T> {
    
    if(list.size == 0) {
      return None
    } 
    
    return Some(list.remove(0))

  }

  public func getSize(): Int64 {
    return list.size
  }

  public func offer(key: T): Bool {

    if(list.size > this.size) {
      return false
    }

    list.append(key)
    return true
  }
  
}

public abstract class BaseKeyPool<T> where T <: Poolable {
  private static let MAX_SIZE: Int64 = 20;
  private let keyPool: Queue<T> = Queue<T>(MAX_SIZE);

  public func get(): T {
    var result: Option<T> = keyPool.poll();
    if (match(result) {
      case Some(x) => false
      case _ => true
    }) {
      return create();
    }
    return result.getOrThrow();
  }

  public func offer(key: T): Unit {
    if (keyPool.getSize() < MAX_SIZE) {
      keyPool.offer(key);
    }
  }

  public func create(): T;
}
