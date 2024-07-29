/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public interface Animatable {
    /**
     * Starts the drawable's animation.
     */
    func start(): Unit;

    /**
     * Stops the drawable's animation.
     */
    func stop(): Unit;

    /**
     * Indicates whether the animation is running.
     *
     * @return True if the animation is running, false otherwise.
     */
    func isRunning(): Bool;
}

public interface Animatable2 <: Animatable {
    func registerAnimationCallback(callback: AnimationCallback): Unit;

    /**
     * Removes the specified animation callback.
     *
     * @param callback Callback to remove.
     * @return {@code false} if callback didn't exist in the call back list, or {@code true} if
     *         callback has been removed successfully.
     */
    func unregisterAnimationCallback(callback: AnimationCallback): Bool;

    /**
     * Removes all existing animation callbacks.
     */
    func clearAnimationCallbacks(): Unit;
}

public interface AnimationCallback <: Equatable<AnimationCallback> {
    /**
        * Called when the animation starts.
        *
        * @param drawable The drawable started the animation.
        */
    func onAnimationStart(drawable: Drawable): Unit;
    /**
        * Called when the animation ends.
        *
        * @param drawable The drawable finished the animation.
        */
    func onAnimationEnd(drawable: Drawable): Unit;
}
