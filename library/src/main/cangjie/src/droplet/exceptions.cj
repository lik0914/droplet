/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

//public class IllegalStateException <: Exception {
//    public IllegalStateException(message: String) {
public class IllegalStateExceptions <: Exception {
    public IllegalStateExceptions(message: String) {
        super(message)
    }
}

public class NullPointerException <: Exception {
    public NullPointerException(message: String) {
        super(message)
    }
}

public class DropletException <: Exception {
    public DropletException(message: String) {
        super(message)
    }
}

public class ExecutionException <: Exception {
    public ExecutionException(message: String) {
        super(message)
    }

    public init(e: DropletException) {
        super(e.message)
    }
}

public class CancellationException <: Exception {
    public CancellationException(message: String) {
        super(message)
    }
}
