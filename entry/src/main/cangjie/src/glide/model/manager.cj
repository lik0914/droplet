package glide.model

from std import sync.*
from std import collection.*

public class Manager {
    private var mtx: ReentrantMutex
    // modelloaders
    private let stringModelLoaders: ArrayList<ModelLoader> = ArrayList<ModelLoader>()
    private let fileModelLoaders: ArrayList<ModelLoader> = ArrayList<ModelLoader>()

    // decoders
    private let drawableResourceDecoders: ArrayList<ResourceDecoder<Array<UInt8>, Drawable>> = ArrayList<ResourceDecoder<Array<UInt8>, Drawable>>()
    private let pixelMapResourceDecoders: ArrayList<ResourceDecoder<Array<UInt8>, PixelMap>> = ArrayList<ResourceDecoder<Array<UInt8>, PixelMap>>()

    private let drawableResourceParser: PixelMapDrawableResourceParser = PixelMapDrawableResourceParser()

    public init(mtx: ReentrantMutex) {
        this.mtx = mtx
        this.stringModelLoaders.append(StringModelLoader())

        this.fileModelLoaders.append(FileModelLoader())

        this.drawableResourceDecoders.append(PixelMapDrawableResourceDecoder())
        this.drawableResourceDecoders.append(GifDrawableResourceDecoder())

        this.pixelMapResourceDecoders.append(PixelMapResourceDecoder())
    }

    public func getStringModelLoaders(): ArrayList<ModelLoader> {
        synchronized (mtx) {
            return stringModelLoaders
        }
    }

    public func getFileModelLoaders(): ArrayList<ModelLoader> {
        synchronized (mtx) {
            return fileModelLoaders
        }
    }

    public func setStringModelLoader(modelLoader: ModelLoader): Unit {
        synchronized (mtx) {
            this.stringModelLoaders.clear()
            this.stringModelLoaders.append(modelLoader)
        }
    }

    public func setFileModelLoader(modelLoader: ModelLoader): Unit {
        synchronized (mtx) {
            this.fileModelLoaders.clear()
            this.fileModelLoaders.append(modelLoader)
        }
    }

    public func addDrawableResourceDecoder(decoder: ResourceDecoder<Array<UInt8>, Drawable>): Unit {
        synchronized (mtx) {
            this.drawableResourceDecoders.append(decoder)
        }
    }

    public func getDrawableResourceParser(): ResourceDecoder<Array<UInt8>, Drawable> {
        synchronized (mtx) {
            return drawableResourceParser
        }
    }

    public func getDrawableResourceDecoders(): ArrayList<ResourceDecoder<Array<UInt8>, Drawable>> {
        synchronized (mtx) {
            return this.drawableResourceDecoders
        }
    }

    public func addPixelMapResourceDecoder(decoder: ResourceDecoder<Array<UInt8>, PixelMap>): Unit {
        synchronized (mtx) {
            this.pixelMapResourceDecoders.append(decoder)
        }
    }

    public func getPixelMapResourceDecoders(): ArrayList<ResourceDecoder<Array<UInt8>, PixelMap>> {
        synchronized (mtx) {
            return this.pixelMapResourceDecoders
        }
    }

}
