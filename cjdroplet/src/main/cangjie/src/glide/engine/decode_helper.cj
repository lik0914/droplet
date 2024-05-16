package glide.engine

from std import collection.*

import glide.engine.pool.*

import gifdecoder.glide.gif.*

public class DecodeHelper {

//   private final List<LoadData<?>> loadData = new ArrayList<>();
  // private let cacheKeys: ArrayList<AnyKey> = ArrayList<AnyKey>();
  // private var isCacheKeysSet: Bool = false;

  private var glideContext: GlideContext;
  private var model: Model;
  private var width: Int64;
  private var height: Int64;
  private var resourceTypeClass: ResourceTypeClass;
  private var diskCacheProvider: DiskCacheProvider;
  private var options: GlideOptions;
  private var transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>;
  private var transformationKey: TransformationKey;
  private var isLoadDataSet: Bool = false;
  
  private var signature: AnyKey;
//   private Priority priority;
  private var diskCacheStrategy: DiskCacheStrategy ;
  private var isTransformationRequired: Bool = false;
  private var isScaleOnlyOrNoTransform: Bool = false;

  private var dataSource: DataSource

  // private var downsampler: Downsampler = Downsampler()

  public init(glideContext: GlideContext,
      model: Model,
      signature: AnyKey ,
      width: Int64,
      height: Int64,
      diskCacheStrategy: DiskCacheStrategy,
      resourceTypeClass: ResourceTypeClass,
      transformationKey: TransformationKey,
    //   Priority priority,
      options: GlideOptions,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      isTransformationRequired: Bool,
      isScaleOnlyOrNoTransform: Bool,
      diskCacheProvider: DiskCacheProvider) {
       this.glideContext = glideContext;
        this.model = model;
        this.signature = signature;
        this.width = width;
        this.height = height;
        this.diskCacheStrategy = diskCacheStrategy;
        this.resourceTypeClass = resourceTypeClass;
        this.diskCacheProvider = diskCacheProvider;
        this.transformationKey = transformationKey;
        // this.priority = priority;
        this.options = options;
        this.transformations = transformations;
        this.isTransformationRequired = isTransformationRequired;
        this.isScaleOnlyOrNoTransform = isScaleOnlyOrNoTransform;

        this.dataSource = model.getDataSource()
  }

  public func isGif(data: Array<UInt8>): Bool {
    return ImageUtils.getImageType(data) == ImageUtils.ImageFormatGIF
  }

  public func getDrawableResourceParser(): ResourceDecoder<Array<UInt8>, Drawable> {
    return glideContext.getManager().getDrawableResourceParser()
  }

  public func getDrawableResourceDecoders(): ArrayList<ResourceDecoder<Array<UInt8>, Drawable>> {
    return glideContext.getManager().getDrawableResourceDecoders()
  }

  public func getPixelMapResourceDecoders(): ArrayList<ResourceDecoder<Array<UInt8>, PixelMap>> {
    return glideContext.getManager().getPixelMapResourceDecoders()
  }

  // public func decodeImage(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64): Option<GlideResource<PixelMapDrawable>> {
  //   AppLog.error("helper decodeImage: ${requestedWidth} -- ${requestedHeight}")
  //   if(isGif(buffer)) {
  //     return None
  //   } else {
  //     return downsampler.decode(buffer, requestedWidth, requestedHeight, this.options)
  //   }
  // }

  // public func decodeImageGIF(buffer: Array<UInt8>, requestedWidth: Int64, requestedHeight: Int64): Option<GifDrawable> {
  //   let headerParser: GifHeaderParser = GifHeaderParser();
  //   headerParser.setData(buffer);
  //   let header: GifHeader = headerParser.parseHeader();
  //   if(header.getFrameCount() <= 0) {
  //     return None
  //   }

  //   let provider = GifBitmapProvider()
  //   let decoder: GifDecoder = StandardGifDecoder(provider);
  //   decoder.setData(header, buffer);

  //   decoder.advance();
  //   let (ret1,firstFrame) = decoder.getNextFrame();
    
  //   return Some(GifDrawable(decoder, requestedWidth, requestedHeight, PixelMap(firstFrame.getData32()), this.getTransformation()))
  // }

  public func getDataSource(): DataSource {
    return this.dataSource
  }

  public func getModel(): Model {
    return model
  }

  public func getModelLoaders(): Option<ArrayList<ModelLoader>> {
    match(model.modelType) {
      // case ModelType.ARRAY => getImageFromArray(model.arr)
      case ModelType.STRING => Some(glideContext.getManager().getStringModelLoaders())
      case ModelType.FILE => Some(glideContext.getManager().getFileModelLoaders())
      case ModelType.GIFDECODER => None
      case _ => None
    }
  }

  public func clear(): Unit {

    // loadData.clear();
    // isLoadDataSet = false;
    // cacheKeys.clear();
    // isCacheKeysSet = false;
  }

  public func getDiskCache(): DiskCache {
    return diskCacheProvider.getDiskCache();
  }

  public func getDiskCacheStrategy(): DiskCacheStrategy {
    return diskCacheStrategy;
  }

//   <T> DataRewinder<T> getRewinder(T data) {
//     return glideContext.getRegistry().getRewinder(data);
//   }

//   Priority getPriority() {
//     return priority;
//   }

  public func getOptions(): GlideOptions {
    return options;
  }

  public func getSignature(): AnyKey {
    return signature;
  }

  public func getWidth(): Int64 {
    return width;
  }

  public func getHeight(): Int64 {
    return height;
  }

  // ArrayPool getArrayPool() {
  //   return glideContext.getArrayPool();
  // }
  public func getArrayPool(): ArrayPool {
      return glideContext.getArrayPool();
  }

    // getTranscodeClass
  public func getTransformationKey(): TransformationKey {
    return transformationKey;
  }

    // getModelClass
//   public func getModelType(): ModelType {
//     return model.modelType;
//   }

  public func getResourceTypeClass(): ResourceTypeClass {
    return resourceTypeClass
  }

//   List<Class<?>> getRegisteredResourceClasses() {
//     return glideContext
//         .getRegistry()
//         .getRegisteredResourceClasses(model.getClass(), resourceClass, transcodeClass);
//   }

//   boolean hasLoadPath(Class<?> dataClass) {
//     return getLoadPath(dataClass) != null;
//   }

//   <Data> LoadPath<Data, ?, Transcode> getLoadPath(Class<Data> dataClass) {
//     return glideContext.getRegistry().getLoadPath(dataClass, resourceClass, transcodeClass);
//   }

  public func getScaleOnlyOrNoTransform(): Bool {
    return isScaleOnlyOrNoTransform;
  }

  public func getTransformation(): Option<AnyTransformation> {
    return getTransformation(this.transformationKey)
  }

  public func getTransformation(transformationKey: TransformationKey): Option<AnyTransformation> {
    // AppLog.error("getTransformation transformations: K: ${transformationKey} v: ${transformations}")
    var result: Option<AnyKey> = transformations.get(transformationKey);
    if (match(result) {
      case Some(x) => false
      case _ => true
    }) {
      // 可能没必要判断 因为不是用Class做的key
      // for (Entry<Class<?>, Transformation<?>> entry : transformations.entrySet()) {
      //   if (entry.getKey().isAssignableFrom(resourceClass)) {
      //     result = (Transformation<Z>) entry.getValue();
      //     break;
      //   }
      // }
    }

    if (match(result) {
      case Some(x) => false
      case _ => true
    }) {
      if (transformations.isEmpty() && isTransformationRequired) {
        throw GlideException(
            "Missing transformation for  xxxtransforms. If you wish to ignore unknown resource types, use the optional transformation methods.");
      } else {

        if(transformationKey.tType == TransformationKey.TRANSFORMATION_PIXELMAP) {
          return UnitTransformation<PixelMap>.get();
        } else if(transformationKey.tType == TransformationKey.TRANSFORMATION_INPUTSTREAM) {
          return UnitTransformation<InputStream>.get();
        } else if(transformationKey.tType == TransformationKey.TRANSFORMATION_DRAWABLE) {
          return UnitTransformation<PixelMap>.get();
        } else {
          throw GlideException("Missing transformation for  xxxtransforms.")
        }
      }
    }

    if(result.getOrThrow() is AnyTransformation) {
      return result.getOrThrow() as AnyTransformation;
    }
    throw GlideException("Missing transformation for  xxxtransforms.   error  !!!")
  }

  public func isResourceEncoderAvailable(resource: AnyGlideResource): Bool {
    // Gif格式不支持缓存变换后的数据 不需要判断gif
    if(resource is GlideResource<PixelMap> || resource is GlideResource<PixelMapDrawable>) {
      return true
    }
    return false
  }


}

public class InputStreamEncoder <: Encoder<InputStream> {
  private let byteArrayPool: ArrayPool;

  public init(byteArrayPool: ArrayPool) {
    this.byteArrayPool = byteArrayPool;
  }

  // @Override
  // public boolean encode(@NonNull InputStream data, @NonNull File file, @NonNull Options options) {
  //   byte[] buffer = byteArrayPool.get(ArrayPool.STANDARD_BUFFER_SIZE_BYTES, byte[].class);
  //   boolean success = false;
  //   OutputStream os = null;
  //   try {
  //     os = new FileOutputStream(file);
  //     int read;
  //     while ((read = data.read(buffer)) != -1) {
  //       os.write(buffer, 0, read);
  //     }
  //     os.close();
  //     success = true;
  //   } catch (IOException e) {
  //     if (Log.isLoggable(TAG, Log.DEBUG)) {
  //       Log.d(TAG, "Failed to encode data onto the OutputStream", e);
  //     }
  //   } finally {
  //     if (os != null) {
  //       try {
  //         os.close();
  //       } catch (IOException e) {
  //         // Do nothing.
  //       }
  //     }
  //     byteArrayPool.put(buffer);
  //   }
  //   return success;
  // }

  public func encode(d: InputStream, file: GlideFile, options: GlideOptions): Bool {

    let buf: Array<UInt8> = byteArrayPool.get(LruArrayPool.STANDARD_BUFFER_SIZE_BYTES);

    var f: File = file.getFile()

    var read: Int64 = 0
    read = d.read(buf)

    // 两种方式性能不确定
    while(read > 0) {
        f.write(buf[0 .. read])
        read = d.read(buf)
    }

    // let buf: Array<UInt8> = Array<UInt8>(d.length, item: 0)
    // d.read(buf)
    // f.write(buf);
    f.close();
    return true;
  }
}

public class UnitTransformation<T> <: Transformation<T> {
  private static let TRANSFORMATION: AnyTransformation = UnitTransformation<T>();

  /**
   * Returns a UnitTransformation for the given type.
   *
   * @param <T> The type of the resource to be transformed.
   */
  public static func get(): Option<AnyTransformation> {
    //return (TRANSFORMATION as AnyTransformation) ;
    return TRANSFORMATION
  }

  public func transform(resource: AnyGlideResource, outWidth: Int64, outHeight: Int64): AnyGlideResource {
    if(resource is GlideResource<T>) {
      let r: GlideResource<T> = (resource as GlideResource<T>).getOrThrow()
      return (transform(r, outWidth, outHeight) as AnyGlideResource).getOrThrow()
    } else {
      return resource
    }
  }

  public func transform(resource: GlideResource<T>, outWidth: Int64, outHeight: Int64): GlideResource<T> {
    return resource;
  }

  public func updateDiskCacheKey(md5: MD5) {
    // Do nothing.
  }

  public func toString(): String {
    return "UnitTransformation"
  }

  public func hashCode(): Int64 {
    return 0
  }

  public operator func ==(that: AnyKey): Bool {
    if(that is UnitTransformation<T>) {
      return true
    } else {
      return false
    }
  }

  public operator func !=(that: AnyKey): Bool {
    if(that is UnitTransformation<T>) {
      return false
    } else {
      return true
    }
  }
}

