package glide

from std import sync.*

// public class GlideExecutor {
//     public func excute(gt: GlideThread): Unit {
//         return gt.run()
//     }
// }

public class GlideExecutor<T> {
    public func execute(gt: GlideThread<T>): Future<T> {
        return gt.run()
    }
}

public abstract class GlideThread<T> {
    public let name: String

    public init(name: String) {
        this.name = name
    }

    public func runWrap(): T

    public func run(): Future<T> {
        return spawn{runWrap()}
    }
}

// public abstract class GlideThread {
//     public let name: String

//     public init(name: String) {
//         this.name = name
//     }

//     public func run(): Unit {
//         spawn{runWrap()}
//     }

//     public func runWrap(): Unit

// }
