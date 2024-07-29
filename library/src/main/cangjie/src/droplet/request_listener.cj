/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

package droplet.droplet


public interface RequestListener<R> {

  /**
   * Called when an exception occurs during a load, immediately before {@link
   * Target#onLoadFailed(Drawable)}. Will only be called if we currently want to display an image
   * for the given model in the given target. It is recommended to create a single instance per
   * activity/fragment rather than instantiate a new object for each call to {@code
   * Droplet.with(fragment/activity).load()} to avoid object churn.
   *
   * <p>It is not safe to reload this or a different model in this callback. If you need to do so
   * use {@link com.bumptech.droplet.RequestBuilder#error(RequestBuilder)} instead.
   *
   * <p>Although you can't start an entirely new load, it is safe to change what is displayed in the
   * {@link Target} at this point, as long as you return {@code true} from the method to prevent
   * {@link Target#onLoadFailed(Drawable)} from being called.
   *
   * <p>For threading guarantees, see the class comment.
   *
   * <p>For example:
   *
   * <pre>{@code
   * public boolean onLoadFailed(Exception e, T model, Target target, boolean isFirstResource) {
   *     target.setPlaceholder(R.drawable.a_specific_error_for_my_exception);
   *     return true; // Prevent onLoadFailed from being called on the Target.
   * }
   * }</pre>
   *
   * @param e The maybe {@code null} exception containing information about why the request failed.
   * @param model The model we were trying to load when the exception occurred.
   * @param target The {@link Target} we were trying to load the image into.
   * @param isFirstResource {@code true} if this exception is for the first resource to load.
   * @return {@code true} to prevent {@link Target#onLoadFailed(Drawable)} from being called on
   *     {@code target}, typically because the listener wants to update the {@code target} or the
   *     object the {@code target} wraps itself or {@code false} to allow {@link
   *     Target#onLoadFailed(Drawable)} to be called on {@code target}.
   */
  func onLoadFailed(e: DropletException, model: Model, target: Target<R>, isFirstResource: Bool): Bool;

  /**
   * Called when a load completes successfully, immediately before {@link
   * Target#onResourceReady(Object, com.bumptech.droplet.request.transition.Transition)}.
   *
   * <p>For threading guarantees, see the class comment.
   *
   * @param resource The resource that was loaded for the target.
   * @param model The specific model that was used to load the image.
   * @param target The target the model was loaded into.
   * @param dataSource The {@link DataSource} the resource was loaded from.
   * @param isFirstResource {@code true} if this is the first resource to in this load to be loaded
   *     into the target. For example when loading a thumbnail and a full-sized image, this will be
   *     {@code true} for the first image to load and {@code false} for the second.
   * @return {@code true} to prevent {@link Target#onResourceReady(Object, Transition)} from being
   *     called on {@code target}, typically because the listener wants to update the {@code target}
   *     or the object the {@code target} wraps itself or {@code false} to allow {@link
   *     Target#onResourceReady(Object, Transition)} to be called on {@code target}.
   */
  func onResourceReady(resource: R, model: Model, target: Target<R>, dataSource: DataSource, isFirstResource: Bool): Bool;
}

public abstract class ExperimentalRequestListener<ResourceT> <: RequestListener<ResourceT> {


  /**
   * Identical to {@link #onResourceReady(Object, Object, Target, DataSource, boolean)} except that
   * {@code isAlternateCacheKey} is provided.
   *
   * @param isAlternateCacheKey True if the data was obtained from the disk cache using an alternate
   *     cache key provided by a {@link com.bumptech.droplet.load.model.ModelLoader} via {@link
   *     com.bumptech.droplet.load.model.ModelLoader.LoadData#alternateKeys}. Valid only if {@code
   *     dataSource} is {@link DataSource#DATA_DISK_CACHE} or {@link
   *     DataSource#RESOURCE_DISK_CACHE}.
   */
  public func onResourceReady(
      resource: ResourceT,
      model: Model,
      target: Target<ResourceT>,
      dataSource: DataSource,
      isFirstResource: Bool,
      isAlternateCacheKey: Bool): Bool;
}

public class NoRequestListener<ResourceT> <: RequestListener<ResourceT> {

  public func onLoadFailed(e: DropletException, model: Model, target: Target<ResourceT>, isFirstResource: Bool): Bool {
    return false
  }

  public func onResourceReady(resource: ResourceT, model: Model, target: Target<ResourceT>, dataSource: DataSource, isFirstResource: Bool): Bool {
    return false
  }

}
