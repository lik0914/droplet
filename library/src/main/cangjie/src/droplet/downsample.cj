/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



/**
* Indicates whether to prefer to prefer downsampling or scaling to prefer lower memory usage or
* higher quality.
*/
public enum SampleSizeRounding {
    /**
        * Prefer to round the sample size up so that the image is downsampled to smaller than the
        * requested size to use less memory.
        */
    MEMORY |
    /**
        * Prefer to round the sample size down so that the image is downsampled to larger than the
        * requested size to maintain quality at the expense of extra memory usage.
        */
    QUALITY
}

public class DownsampleFitCenter <: DownsampleStrategy {

    public let label: String = "DownsampleFitCenter"

    public override func getScaleFactor(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): Float64 {
        var widthPercentage: Float64 = Float64(requestedWidth) / Float64(sourceWidth);
        var heightPercentage: Float64 = Float64(requestedHeight) / Float64(sourceHeight);

        return min(widthPercentage, heightPercentage);
    }

    public override func getSampleSizeRounding(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): SampleSizeRounding {
        return SampleSizeRounding.QUALITY;
    }

    public func toString(): String {
        return label
    }

    public func hashCode(): Int64 {
        return label.hashCode()
    }

    public operator func ==(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleFitCenter) {
            return true
        } else {
            return false
        }
    }

    public operator func !=(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleFitCenter) {
            return false
        } else {
            return true
        }
    }
}

public class DownsampleCenterOutside <: DownsampleStrategy {

    public let label: String = "DownsampleCenterOutside"

    public override func getScaleFactor(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): Float64 {
        var widthPercentage: Float64 = Float64(requestedWidth) / Float64(sourceWidth);
        var heightPercentage: Float64 = Float64(requestedHeight) / Float64(sourceHeight);
        return max(widthPercentage, heightPercentage);
    }

    public override func getSampleSizeRounding(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): SampleSizeRounding {
        return SampleSizeRounding.QUALITY;
    }

    public func toString(): String {
        return label
    }

    public func hashCode(): Int64 {
        return label.hashCode()
    }

    public operator func ==(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleCenterOutside) {
            return true
        } else {
            return false
        }
    }

    public operator func !=(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleCenterOutside) {
            return false
        } else {
            return true
        }
    }
}

public class DownsampleAtLeast <: DownsampleStrategy {

    public let label: String = "DownsampleAtLeast"

    public override func getScaleFactor(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): Float64 {
        var minIntegerFactor: Int64 = min(sourceHeight / requestedHeight, sourceWidth / requestedWidth);
        if(minIntegerFactor == 0) {
            return 1.0
        } else {
            return 1.0 / Float64(minIntegerFactor)
        }
    }

    public func getSampleSizeRounding(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): SampleSizeRounding {
        return SampleSizeRounding.QUALITY;
    }

    public func toString(): String {
        return label
    }

    public func hashCode(): Int64 {
        return label.hashCode()
    }

    public operator func ==(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleAtLeast) {
            return true
        } else {
            return false
        }
    }

    public operator func !=(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleAtLeast) {
            return false
        } else {
            return true
        }
    }
}

public class DownsampleAtMost <: DownsampleStrategy {

    public let label: String = "DownsampleAtMost"

    public override func getScaleFactor(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): Float64 {
        var maxIntegerFactor: Int64 = Int64(ceil(max(Float64(sourceHeight) / Float64(requestedHeight), Float64(sourceWidth) / Float64(requestedWidth))));
        var lesserOrEqualSampleSize: Int64 = max(1, maxIntegerFactor);
        
        var greaterOrEqualSampleSize: Int64 = lesserOrEqualSampleSize << (if(lesserOrEqualSampleSize < maxIntegerFactor) { 1 } else { 0 });
        return 1.0 / Float64(greaterOrEqualSampleSize);
    }

    public func getSampleSizeRounding(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): SampleSizeRounding {
        return SampleSizeRounding.MEMORY;
    }

    public func toString(): String {
        return label
    }

    public func hashCode(): Int64 {
        return label.hashCode()
    }

    public operator func ==(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleAtMost) {
            return true
        } else {
            return false
        }
    }

    public operator func !=(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleAtMost) {
            return false
        } else {
            return true
        }
    }
}

public class DownsampleNone <: DownsampleStrategy {

    public let label: String = "DownsampleNone"

    public override func getScaleFactor(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): Float64 {
        return 1.0;
    }

    public override func getSampleSizeRounding(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): SampleSizeRounding{
        return SampleSizeRounding.QUALITY;
    }

    public func toString(): String {
        return label
    }

    public func hashCode(): Int64 {
        return label.hashCode()
    }

    public operator func ==(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleNone) {
            return true
        } else {
            return false
        }
    }

    public operator func !=(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleNone) {
            return false
        } else {
            return true
        }
    }
}

public class DownsampleCenterInside <: DownsampleStrategy {

    public let label: String = "DownsampleCenterInside"

    public override func getScaleFactor(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): Float64 {
        return min(1.0, FIT_CENTER.getScaleFactor(sourceWidth, sourceHeight, requestedWidth, requestedHeight));
    }

    public override func getSampleSizeRounding(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): SampleSizeRounding {
        return if(getScaleFactor(sourceWidth, sourceHeight, requestedWidth, requestedHeight) == 1.0) {
            SampleSizeRounding.QUALITY;
        } else {
            FIT_CENTER.getSampleSizeRounding(sourceWidth, sourceHeight, requestedWidth, requestedHeight);
        }
    }

    public func toString(): String {
        return label
    }

    public func hashCode(): Int64 {
        return label.hashCode()
    }

    public operator func ==(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleCenterInside) {
            return true
        } else {
            return false
        }
    }

    public operator func !=(that: AnyDropletOptionValue): Bool {
        if(that is DownsampleCenterInside) {
            return false
        } else {
            return true
        }
    }
}

public abstract class DownsampleStrategy <: AnyDropletOptionValue {

  /**
   * Downsamples so the image's smallest dimension is between the given dimensions and 2x the given
   * dimensions, with no size restrictions on the image's largest dimension.
   *
   * <p>Does not upscale if the requested dimensions are larger than the original dimensions.
   */
  public static let AT_LEAST: DownsampleStrategy = DownsampleAtLeast();

  /**
   * Downsamples so the image's largest dimension is between 1/2 the given dimensions and the given
   * dimensions, with no restrictions on the image's smallest dimension.
   *
   * <p>Does not upscale if the requested dimensions are larger than the original dimensions.
   */
  public static let AT_MOST: DownsampleStrategy = DownsampleAtMost();

  /**
   * Scales, maintaining the original aspect ratio, so that one of the image's dimensions is exactly
   * equal to the requested size and the other dimension is less than or equal to the requested
   * size.
   *
   * <p>This method will upscale if the requested width and height are greater than the source width
   * and height. To avoid upscaling, use {@link #AT_LEAST}, {@link #AT_MOST} or {@link
   * #CENTER_INSIDE}.
   *
   * <p>On pre-KitKat devices, {@code FIT_CENTER} will downsample by a power of two only so that one
   * of the image's dimensions is greater than or equal to the requested size. No guarantees are
   * made about the second dimensions. This is <em>NOT</em> the same as {@link #AT_LEAST} because
   * only one dimension, not both, are greater than or equal to the requested dimensions, the other
   * may be smaller.
   */
  public static let FIT_CENTER: DownsampleStrategy = DownsampleFitCenter();

  /** Identical to {@link #FIT_CENTER}, but never upscales. */
  public static let CENTER_INSIDE: DownsampleStrategy = DownsampleCenterInside();

  /**
   * Scales, maintaining the original aspect ratio, so that one of the image's dimensions is exactly
   * equal to the requested size and the other dimension is greater than or equal to the requested
   * size.
   *
   * <p>This method will upscale if the requested width and height are greater than the source width
   * and height. To avoid upscaling, use {@link #AT_LEAST}, {@link #AT_MOST}, or {@link
   * #CENTER_INSIDE}.
   *
   * <p>On pre-KitKat devices, {@link Downsampler} treats this as equivalent to {@link #AT_LEAST}
   * because only power of two downsampling can be used.
   */
  public static let CENTER_OUTSIDE: DownsampleStrategy = DownsampleCenterOutside();

  /** Performs no downsampling or scaling. */
  public static let NONE: DownsampleStrategy = DownsampleNone();

  /** Default strategy, currently {@link #CENTER_OUTSIDE}. */
  public static let DEFAULT: DownsampleStrategy = FIT_CENTER;

  /**
   * Indicates the {@link com.bumptech.droplet.load.resource.bitmap.DownsampleStrategy} option that
   * will be used to calculate the sample size to use to downsample an image given the original and
   * target dimensions of the image.
   */
  // The exact String value here is retained to avoid breaking cache keys for images that were
  // loaded with older versions of Droplet.
  public static let OPTION: DropletOption<DownsampleStrategy> = DropletOption<DownsampleStrategy>.memory("com.bumptech.droplet.load.resource.bitmap.Downsampler.DownsampleStrategy", DEFAULT);

    public static let IS_BITMAP_FACTORY_SCALING_SUPPORTED: Bool = true

  /**
   * Returns a float (0, +infinity) indicating a scale factor to apply to the source width and
   * height when displayed in the requested width and height.
   *
   * <p>The returned scale factor will be split into a power of two sample size applied via {@link
   * android.graphics.BitmapFactory.Options#inSampleSize} and a float scale factor applied after
   * downsampling via {@link android.graphics.BitmapFactory.Options#inTargetDensity} and {@link
   * android.graphics.BitmapFactory.Options#inDensity}. Because of rounding errors the scale factor
   * may not be applied precisely.
   *
   * <p>The float scaling factor will only be applied on KitKat+. Prior to KitKat, only the power of
   * two downsampling will be applied.
   *
   * @param sourceWidth The width in pixels of the image to be downsampled.
   * @param sourceHeight The height in pixels of the image to be downsampled.
   * @param requestedWidth The width in pixels of the view/target the image will be displayed in.
   * @param requestedHeight The height in pixels of the view/target the image will be displayed in.
   */
  public func getScaleFactor(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): Float64;

  /**
   * Returns a non-null {@link SampleSizeRounding} to use to resolve rounding errors and conflicts
   * between scaling for the width and the height of the image.
   *
   * @param sourceWidth The width in pixels of the image to be downsampled.
   * @param sourceHeight The height in pixels of the image to be downsampled.
   * @param requestedWidth The width in pixels of the view/target the image will be displayed in.
   * @param requestedHeight The height in pixels of the view/target the image will be displayed in.
   */
  public func getSampleSizeRounding(sourceWidth: Int64, sourceHeight: Int64, requestedWidth: Int64, requestedHeight: Int64): SampleSizeRounding;
}
