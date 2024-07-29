/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


// public class DropletExecutor {
//     public func excute(gt: DropletThread): Unit {
//         return gt.run()
//     }
// }

public class DropletExecutor<T> {
    public func execute(gt: DropletThread<T>): Future<T> {
        return gt.run()
    }
}

public abstract class DropletThread<T> {
    public let name: String

    public init(name: String) {
        this.name = name
    }

    public func runWrap(): T

    public func run(): Future<T> {
        return spawn{runWrap()}
    }
}

// public abstract class DropletThread {
//     public let name: String

//     public init(name: String) {
//         this.name = name
//     }

//     public func run(): Unit {
//         spawn{runWrap()}
//     }

//     public func runWrap(): Unit

// }
