package glide.request

public interface TransitionDrawableAdapter {
    func getDrawable(): Option<Drawable>
    func getCurrentDrawable(): Option<Drawable>
}

public class DrawableTransition <: Transition<Drawable> {
    public func transition(current: Drawable, adapter: TransitionDrawableAdapter): Bool {
        // TODO 过渡动画
        return true
    }
}

public interface Transition<R> {
    func transition(current: R, adapter: TransitionDrawableAdapter): Bool
}
