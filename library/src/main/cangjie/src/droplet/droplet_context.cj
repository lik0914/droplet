/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



public class DropletContext {
    private let mtx = ReentrantMutex()
    private var defaultRequestOptions: Option<RequestOptions> = None
    private let defaultRequestOptionsFactory: RequestOptionsFactory;
    
    public var ctx: AbilityContext;

    private let manager: Manager = Manager(mtx)

    public var arrayPool: ArrayPool

    public let openGLThreadExcutor:OpenGLThreadExcutor
    public let customMonitorGL:CustomMonitor
    public let customMonitorTask:CustomMonitor
    private let glProcessLock:ReentrantMutex = ReentrantMutex()


    public init(defaultRequestOptionsFactory: RequestOptionsFactory, context: AbilityContext, arrayPool: ArrayPool) {
        this.defaultRequestOptionsFactory = defaultRequestOptionsFactory
        this.ctx = context
        this.arrayPool = arrayPool
        let glMonitor:Monitor = Monitor()
        this.customMonitorGL = CustomMonitor(glMonitor)
        let taskMonitor:Monitor = Monitor()
        this.customMonitorTask = CustomMonitor(taskMonitor)
        this.openGLThreadExcutor = OpenGLThreadExcutor()
        this.openGLThreadExcutor.openGLStartThread()

    }

    public func getDefaultRequestOptions(): RequestOptions {
        synchronized (mtx) {
            if (match(defaultRequestOptions) {
                    case Some(x) => false
                    case _ => true
                }) {
                defaultRequestOptions = Some(defaultRequestOptionsFactory.build().lock());
            }
            return defaultRequestOptions.getOrThrow();
        }
    }

    public func getManager(): Manager {
        return this.manager
    }

    public func getArrayPool(): ArrayPool {
        return arrayPool;
    }

}
