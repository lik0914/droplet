/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



public interface FrameCallback <: Equatable<FrameCallback> {
    func onFrameReady(): Unit;
}

public class GifFrameLoader {
    public var gifDecoder: GifDecoder

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
        stop();
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
                if(currentFrameIndex < frameList.size) {
                    let r: PixelMap = frameList[currentFrameIndex]
                    onFrameReady()
                    sleep(Duration.millisecond * Int64(frameDelayList[currentFrameIndex]))
                } else {

                    mon.lock()
                    flag = true
                    mon.unlock()
                    mon.lock()
                    while (flag) {
                    mon.wait()
                    }
                    mon.unlock()

                    let r: PixelMap = frameList[currentFrameIndex]
                    onFrameReady()
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
            gifDecoder.resetFrameIndex();
            startFromFirstFrame = false;
        }
        // // Get the delay before incrementing the pointer because the delay indicates the amount of time
        // // we want to spend on the current frame.
        // 解码
        if(match(decodeFuture) {
            case Some(x) => false
            case _ => true
        }) {
            decodeFuture = Some(spawn {
                for(i in 0..getFrameCount() - 1) {
                    gifDecoder.advance();
                    let (ret1, frame) = gifDecoder.getNextFrame();
                    frameList.append(frame)
                    frameDelayList.append(gifDecoder.getNextDelay())
                    mon.lock()
                    flag = false
                    mon.unlock()
                    mon.lock()
                    mon.notifyAll()
                    mon.unlock()
                }
                isDecoding = false;
            })
        }
    }
    public func onFrameReady(): Unit {
        for (i in 0 .. callbacks.size) {
            let cb: FrameCallback = callbacks[i];
            cb.onFrameReady();
        }
        
        loadNextFrame();
    }

}
