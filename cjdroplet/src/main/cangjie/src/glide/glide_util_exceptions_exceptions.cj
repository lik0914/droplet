package glide

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

public class GlideException <: Exception {
    public GlideException(message: String) {
        super(message)
    }
}

public class ExecutionException <: Exception {
    public ExecutionException(message: String) {
        super(message)
    }

    public init(e: GlideException) {
        super(e.message)
    }
}

public class CancellationException <: Exception {
    public CancellationException(message: String) {
        super(message)
    }
}
