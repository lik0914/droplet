package glide.load.resource.gif

from std import sync.*
from std import sync.sleep
from std import time.Duration

public interface FrameCallback <: Equatable<FrameCallback> {
    func onFrameReady(): Unit;
}

public class GifFrameLoader {
    public var gifDecoder: GifDecoder

    // public var firstFrame: PixelMap
    public var transformation: Option<AnyTransformation> = None

    public var firstFrameSize: Int32 = 0

    public var frameList: ArrayList<PixelMap> = ArrayList<PixelMap>()
    public var currentFrameIndex: Int64 = 0
    public var frameDelayList: ArrayList<Int32> = ArrayList<Int32>()

    public var flag: Bool = true

    private var callbacks: ArrayList<FrameCallback> = ArrayList<FrameCallback>();

    public var decodeFuture: Option<Future<Unit>> = None

    public var resFuture: Option<Future<Unit>> = None

    private var isRunning: Bool = false;
    private var isDecoding: Bool = false;
    private var startFromFirstFrame: Bool = false;
    private var isCleared: Bool = false;

    public let mon = Monitor()
    private var mWidth:Int64
    private var mHeight:Int64


    public init(gifDecoder: GifDecoder, width: Int64, height: Int64, firstFrame: PixelMap, transformation: Option<AnyTransformation>) {
        this.gifDecoder = gifDecoder
        
        this.frameList.append(firstFrame)
        //TODO gif
        this.frameDelayList.append(gifDecoder.getNextDelay())

        this.transformation = transformation

        // TODO
        this.firstFrameSize = 0
        this.mWidth = width
        this.mHeight = height
    }

    public func getSize(): Int32 {
        //TODO gif
        //return this.gifDecoder.getByteSize() + firstFrameSize;
        return this.gifDecoder.getFrameCount() * Int32(this.frameList[0].getPixelBytesNumber())
    }

    public func getFrameCount(): Int64 {
        //TODO gif
        return Int64(this.gifDecoder.getFrameCount())
    }

    public func getCurrentIndex(): Int64 {
        return currentFrameIndex
    }

    public func getCurrentFrame(): PixelMap {
        return frameList[currentFrameIndex]
    }

    public func subscribe(frameCallback: FrameCallback): Unit {
        if (isCleared) {
            throw IllegalStateException("Cannot subscribe to a cleared frame loader");
        }

        // if (callbacks.contains(frameCallback)) {
        //     throw IllegalStateException("Cannot subscribe twice in a row");
        // }
        for(cb in callbacks) {
            if(cb == frameCallback) {
                throw IllegalStateException("Cannot subscribe twice in a row");
            }
        }
        
        let start: Bool = callbacks.isEmpty();
        callbacks.append(frameCallback);
        if (start) {
            startFunc();
        }
    }

    func unsubscribe(frameCallback: FrameCallback): Unit {
        //callbacks.remove(frameCallback);
        for(i in 0 .. callbacks.size) {
            if(callbacks[i] == frameCallback) {
                callbacks.remove(i)
            }
        }

        if (callbacks.isEmpty()) {
            stop();
        }
    }

    private func stop(): Unit {
        isRunning = false;
    }

    public func clear(): Unit {
        callbacks.clear();
        // recycleFirstFrame();
        stop();
        // if (current != null) {
        // requestManager.clear(current);
        // current = null;
        // }
        // if (next != null) {
        // requestManager.clear(next);
        // next = null;
        // }
        // if (pendingTarget != null) {
        // requestManager.clear(pendingTarget);
        // pendingTarget = null;
        // }
        gifDecoder.clear();
        isCleared = true;
    }

    public func getLoopCount(): Int64 {
        return Int64(gifDecoder.getTotalIterationCount());
    }

    private func startFunc(): Unit {
        if (isRunning) {
            return;
        }
        isRunning = true;
        isCleared = false;
        isDecoding = true

        loadNextFrame();

        // 显示
        resFuture = Some(spawn {
            while(isRunning) {
                AppLog.error("currentFrameIndex: ${currentFrameIndex} --- ${getFrameCount()}  --- ${frameList.size}")
                if(currentFrameIndex < frameList.size) {
                    let r: PixelMap = frameList[currentFrameIndex]
                    AppLog.error("show Image ${currentFrameIndex + 1}")
                    onFrameReady()
                    AppLog.error("next delay is: ${frameDelayList[currentFrameIndex]}")
                    //适配
                    sleep(Duration.millisecond * Int64(frameDelayList[currentFrameIndex]))
                } else {

                    mon.lock()
                    AppLog.error("show Main thread: set flag")
                    flag = true
                    mon.unlock()
                    mon.lock()
                    while (flag) {
                    AppLog.error("show New thread: before wait")
                    mon.wait()
                    AppLog.error("show New thread: after wait")
                    }
                    mon.unlock()

                    AppLog.error("show frameList size: ${frameList.size}")
                    let r: PixelMap = frameList[currentFrameIndex]
                    AppLog.error("show Image ${currentFrameIndex + 1}")
                    onFrameReady()
                    AppLog.error("next delay is: ${frameDelayList[currentFrameIndex]}")
                    //适配
                    //sleep(Duration.millisecond * 100)
                    sleep(Duration.millisecond * Int64(frameDelayList[currentFrameIndex]))

                }
                currentFrameIndex++

                if(currentFrameIndex >= getFrameCount()) {
                    currentFrameIndex = 0
                }
            }
        })
    }

    private func loadNextFrame(): Unit {
        if (!isRunning || !isDecoding) {
            return;
        }
        if (startFromFirstFrame) {
            // Preconditions.checkArgument(
            //     pendingTarget == null, "Pending target must be null when starting from the first frame");
            gifDecoder.resetFrameIndex();
            startFromFirstFrame = false;
        }
        // if (pendingTarget != null) {
        // DelayTarget temp = pendingTarget;
        // pendingTarget = null;
        // onFrameReady(temp);
        // return;
        // }
        // isLoadPending = true;
        // // Get the delay before incrementing the pointer because the delay indicates the amount of time
        // // we want to spend on the current frame.
        // int delay = gifDecoder.getNextDelay();
        // long targetTime = SystemClock.uptimeMillis() + delay;

        // gifDecoder.advance();
        // next = new DelayTarget(handler, gifDecoder.getCurrentFrameIndex(), targetTime);
        // requestBuilder.apply(signatureOf(getFrameSignature())).load(gifDecoder).into(next);

        // 解码
        if(match(decodeFuture) {
            case Some(x) => false
            case _ => true
        }) {
            decodeFuture = Some(spawn {
                for(i in 0..getFrameCount() - 1) {
                    gifDecoder.advance();
                    let (ret1, frame) = gifDecoder.getNextFrame();
                    // var b:XBitmap=XBitmap(header.getWidth(), header.getHeight())
                    // b.setData(frame.getData32())
                    // sleep(200*1000*1000)
                    //let size: Size = Size(width: frame.width, height: frame.height)
	                //let opts: InitializationOptions = InitializationOptions(size)
                    //frameList.append(PixelMap(frame.getData32(), UInt32(frame.len), opts))
                    frameList.append(frame)
                    frameDelayList.append(gifDecoder.getNextDelay())
                    AppLog.error("decode frameList size: ${frameList.size}")
                    mon.lock()
                    AppLog.error("decode Main thread: set flag")
                    flag = false
                    mon.unlock()

                    AppLog.error("decode Main thread: notify")
                    mon.lock()
                    mon.notifyAll()
                    mon.unlock()
                }
                isDecoding = false;
            })
        }
    }
    public func onFrameReady(): Unit {
        // if (onEveryFrameListener != null) {
        //     onEveryFrameListener.onFrameReady();
        // }
        // isLoadPending = false;

        // for (int i = callbacks.size - 1; i >= 0; i--) {
        //     let cb: FrameCallback = callbacks[i];
        //     cb.onFrameReady();
        // }
        for (i in 0 .. callbacks.size) {
            let cb: FrameCallback = callbacks[i];
            cb.onFrameReady();
        }
        
        loadNextFrame();
    }

}
