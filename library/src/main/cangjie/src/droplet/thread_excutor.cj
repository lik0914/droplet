/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

foreign func getThreadId(): UInt64
foreign func startThread(): UInt64
foreign func stopThread(): Unit
foreign func setTask(param: UInt32): UInt32

public class OpenGLThreadExcutor {

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
