/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

import ohos.state_manage.*
import ohos.state_macro_manage.*


public abstract class AnimatableTarget<R> <: BaseTarget<R> & TransitionDrawableAdapter {
    protected var animatable: Option<Animatable> = Option<Animatable>.None
    protected var drawFunc: (PixelMap) -> Unit
    protected var drawFuncCJResource: (CJResource,Bool) -> Unit

    protected var width: Int64 = -1;
    protected var height: Int64 = -1;

    public init(f: (PixelMap) -> Unit, drawFuncCJResource: (CJResource,Bool) -> Unit, width: Int64, height: Int64) {
        this.drawFunc = f
        this.drawFuncCJResource = drawFuncCJResource
        this.width = width
        this.height = height
    }

    public func onLoadStarted(placeholder: Option<CJResourceDrawable>): Unit {
        setResourceInternal(Option<R>.None);
        setCJResourceDrawable(placeholder,false);
    }

    public func onLoadFailed(errorDrawable: Option<CJResourceDrawable>): Unit {
        setResourceInternal(Option<R>.None);
        setCJResourceDrawable(errorDrawable,true);
    }

    public func onLoadCleared(placeholder: Option<CJResourceDrawable>): Unit {
        if (match(animatable) {
            case Some(x) => true
            case _ => false
        }) {
            animatable.getOrThrow().stop();
        }
        setResourceInternal(Option<R>.None);
        setCJResourceDrawable(placeholder,false);
    }
    
    public func onStart(): Unit {
        if (match(animatable) {
            case Some(x) => true
            case _ => false
        }) {
            animatable.getOrThrow().start();
        }
    }

    public func onStop(): Unit {
        if (match(animatable) {
            case Some(x) => true
            case _ => false
        }) {
            animatable.getOrThrow().stop();
        }
    }

    public func onDestroy(): Unit {
        animatable = Option<Animatable>.None
    }

    // transition
    public func getDrawable(): Option<Drawable> {
        return None
    }

    public func getCurrentDrawable(): Option<Drawable> {
        return None
    }

    public func setCJResourceDrawable(drawable: Option<CJResourceDrawable>,isErrorPic:Bool): Unit {
        if(match(drawable) {
            case Some(x) => true
            case _ => false
        }) {
            drawable.getOrThrow().setDrawFuncCJResource(drawFuncCJResource)
            drawable.getOrThrow().draw(isErrorPic)
        }
    }

    public func getSize(cb: SizeReadyCallback): Unit {
        cb.onSizeReady(width, height);
    }

    protected func setResourceInternal(resource: Option<R>): Unit {
        // Order matters here. Set the resource first to make sure that the Drawable has a valid and
        // non-null Callback before starting it.
        setResource(resource);
        maybeUpdateAnimatable(resource);
    }

    protected func maybeUpdateAnimatable(resource: Option<R>): Unit {
        if(match(resource) {
            case Some(x) => false
            case _ => true
        }) {
            return
        }
        let r: R = resource.getOrThrow()
        if (r is Animatable) {
            animatable = r as Animatable
            animatable.getOrThrow().start();
        } else {
            animatable = None;
        }
    }

    protected func setResource(resource: Option<R>): Unit

}

public class DrawableTarget <: AnimatableTarget<Drawable> {

    public init(f: (PixelMap) -> Unit, width: Int64, height: Int64) {
        super(f, {r: CJResource,isErrorPic:Bool => }, width, height)
    }

    public init(f: (PixelMap) -> Unit, drawFuncCJResource: (CJResource,Bool) -> Unit, width: Int64, height: Int64) {
        super(f, drawFuncCJResource, width, height)
    }

    public func onResourceReady(resource: Drawable, transition: Option<DrawableTransition>): Unit {
        let bo = match(transition) {
            case Some(x) => false
            case _ => true
        }
        if (match(transition) {
            case Some(x) => false
            case _ => true
        } || !(transition.getOrThrow().transition(resource, this))) {
            setResourceInternal(Some(resource));
        } else {
            maybeUpdateAnimatable(Some(resource));
        }
    }

    protected func setResource(resource: Option<Drawable>): Unit {
        if(match(resource) {
            case Some(x) => true
            case _ => false
        }) {
            resource.getOrThrow().setDrawFunc(drawFunc)
            resource.getOrThrow().draw(false)
        }
    }


    public func removeCallback(): Unit {
        // 不支持监听显示组件尺寸变化，需要接口
    }

    public override func hashCode(): Int64 {
        Utils.hashCodeWrite(width.hashCode(), reset: true)
        Utils.hashCodeWrite(height.hashCode())
        if(match(request) {
        case Some(x) => true
        case _ => false
        }) {
            Utils.hashCodeWrite(request.getOrThrow().hashCode())
        }
        return Utils.hashCodeFinish()
    }

    public operator func ==(that: LifecycleListener): Bool {
        if(that is DrawableTarget) {
            return this.request == (that as DrawableTarget).getOrThrow().request
        }
        return false
    }

    public operator func !=(that: LifecycleListener): Bool {
        if(that is DrawableTarget) {
            return this.request != (that as DrawableTarget).getOrThrow().request
        }
        return true
    }

    public operator func ==(that: AnyTarget): Bool {
        if(that is DrawableTarget) {
            return this.request == (that as DrawableTarget).getOrThrow().request
        }
        return false
    }

    public operator func !=(that: AnyTarget): Bool {
        if(that is DrawableTarget) {
            return this.request != (that as DrawableTarget).getOrThrow().request
        }
        return true
    }
}

public class StringDrawableTarget <: AnimatableTarget<Drawable> {

    public init(width: Int64, height: Int64) {
        super({p: PixelMap => 
            AppStorage.setOrCreate<PixelMap>("pixelStore", p)
        }, {r: CJResource,isErrorPic:Bool => }, width, height)
    }

    public func onResourceReady(resource: Drawable, transition: Option<DrawableTransition>): Unit {
        let bo = match(transition) {
            case Some(x) => false
            case _ => true
        }
        if (match(transition) {
            case Some(x) => false
            case _ => true
        } || !(transition.getOrThrow().transition(resource, this))) {
            setResourceInternal(Some(resource));
        } else {
            maybeUpdateAnimatable(Some(resource));
        }
    }

    protected func setResource(resource: Option<Drawable>): Unit {
        if(match(resource) {
            case Some(x) => true
            case _ => false
        }) {
            resource.getOrThrow().setDrawFunc(drawFunc)
            resource.getOrThrow().draw(false)
        }
    }

    public func removeCallback(): Unit {

        // 不支持监听显示组件尺寸变化，需要接口
    }

    public override func hashCode(): Int64 {
        Utils.hashCodeWrite(width.hashCode(), reset: true)
        Utils.hashCodeWrite(height.hashCode())
        if(match(request) {
        case Some(x) => true
        case _ => false
        }) {
            Utils.hashCodeWrite(request.getOrThrow().hashCode())
        }
        return Utils.hashCodeFinish()
    }

    public operator func ==(that: LifecycleListener): Bool {
        if(that is DrawableTarget) {
            return this.request == (that as DrawableTarget).getOrThrow().request
        }
        return false
    }

    public operator func !=(that: LifecycleListener): Bool {
        if(that is DrawableTarget) {
            return this.request != (that as DrawableTarget).getOrThrow().request
        }
        return true
    }

    public operator func ==(that: AnyTarget): Bool {
        if(that is DrawableTarget) {
            return this.request == (that as DrawableTarget).getOrThrow().request
        }
        return false
    }

    public operator func !=(that: AnyTarget): Bool {
        if(that is DrawableTarget) {
            return this.request != (that as DrawableTarget).getOrThrow().request
        }
        return true
    }
}

