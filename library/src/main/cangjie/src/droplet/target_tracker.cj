/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class TargetTracker <: LifecycleListener {
    public let targets: HashSet<AnyTarget> = HashSet<AnyTarget>()

    public func track(target: AnyTarget): Unit {
        targets.put(target);
    }

    public func untrack(target: AnyTarget): Unit {
        targets.remove(target);
    }

    public func getAll(): ArrayList<AnyTarget> {
        return Utils.getSnapshot<AnyTarget>(targets);
    }

    public func clear(): Unit {
        targets.clear();
    }

    public override func onStart(): Unit {
        for (target in Utils.getSnapshot<AnyTarget>(targets)) {
            target.onStart();
        }
    }

    public override func onStop(): Unit {
        for (target in Utils.getSnapshot<AnyTarget>(targets)) {
            target.onStop();
        }
    }

    public override func onDestroy(): Unit {
        for (target in Utils.getSnapshot<AnyTarget>(targets)) {
            target.onDestroy();
        }
    }

    public override func hashCode(): Int64 {
        Utils.hashCodeReset()
        for(t in targets) {
            Utils.hashCodeWrite(t.hashCode())
        }
        return Utils.hashCodeFinish()
    }

    public operator func ==(that: LifecycleListener): Bool {
        if(that is TargetTracker) {
            return refEq(this, (that as TargetTracker).getOrThrow())
        }
        return false
    }

    public operator func !=(that: LifecycleListener): Bool {
        if(that is TargetTracker) {
            return !refEq(this, (that as TargetTracker).getOrThrow())
        }
        return true
    }
}
