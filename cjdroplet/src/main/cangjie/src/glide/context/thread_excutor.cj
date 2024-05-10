package glide.context

import glide.executor.*
import glide.util.exceptions.*

foreign func getThreadId(): UInt64
foreign func startThread(): UInt64
foreign func stopThread(): Unit
foreign func setTask(param: UInt32): UInt32

public class OpenGLThreadExcutor {
    // public var runFlag: Bool
    // public let monitor: CustomMonitor
    // public let taskMonitor: CustomMonitor
    // public var flag: Bool
    // public var task: Option<AnyOpenGLTask> = None

    // public init(m: CustomMonitor, taskMonitor: CustomMonitor) {
    //     this.monitor = m
    //     this.runFlag = true
    //     this.flag = true
    //     this.taskMonitor = taskMonitor
    // }

    public func openGLGetThreadId(): UInt64 {
        return unsafe{getThreadId()}
    }

    public func openGLStartThread(): UInt64 {
        return unsafe{startThread()}
    }

    public func openGLStopThread(): Unit {
        return unsafe{stopThread()}
    }

    public func openGLSetTask(param: UInt32): UInt32 {
        return unsafe{setTask(param)}
    }

}
