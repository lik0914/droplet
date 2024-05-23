package glide

/**
 * Priorities for completing loads. If more than one load is queued at a time, the load with the
 * higher priority will be started first. Priorities are considered best effort, there are no
 * guarantees about the order in which loads will start or finish.
 */
// public enum Priority {
//   IMMEDIATE |
//   HIGH |
//   NORMAL |
//   LOW
// }

public class Priority <: Equatable<Priority> & ToString {

  private static let immediate: Int64 = 1
  private static let high: Int64 = 2
  private static let normal: Int64 = 3
  private static let low: Int64 = 4
  private static let none: Int64 = 0
  
  public static let IMMEDIATE: Priority = Priority(immediate)
  public static let HIGH: Priority = Priority(high)
  public static let NORMAL: Priority = Priority(normal)
  public static let LOW: Priority = Priority(low)
  public static let NONE: Priority = Priority(none)

  

  public var priority: Int64 = none

  public init(priority: Int64) {
    this.priority = priority
  }

  public operator func ==(that: Priority): Bool {
    return this.priority == that.priority
  }

  public operator func !=(that: Priority): Bool {
    return this.priority != that.priority
  }

  public func toString(): String {
    if(this.priority == immediate) {
      return "Priority : immediate"
    } else if(this.priority == high) {
      return "Priority : high"
    } else if(this.priority == normal) {
      return "Priority : normal"
    } else if(this.priority == low) {
      return "Priority : low"
    } else if(this.priority == none) {
      return "Priority : none"
    }
    return "Priority : error"
  }
}
