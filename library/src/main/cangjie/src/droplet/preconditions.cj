/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class Preconditions {
    private Preconditions() {
    // Utility class.
    }

    public static func checkArgument(expression: Bool, message: String) {
        if (!expression) {
            throw IllegalArgumentException(message);
        }
    }

    public static func checkNotNull<T>(arg: Option<T>): T {
        return checkNotNull(arg, "Argument must not be null");
    }

    public static func checkNotNull<T>(arg: Option<T>, message: String ): T {
        if (match(arg) {
            case Some(x) => false
            case _ => true
        }) {
            throw NullPointerException(message);
        }
        return arg.getOrThrow();
    }

    // @NonNull
    // public static String checkNotEmpty(@Nullable String string) {
    // if (TextUtils.isEmpty(string)) {
    //     throw new IllegalArgumentException("Must not be null or empty");
    // }
    // return string;
    // }

    // @NonNull
    // public static <T extends Collection<Y>, Y> T checkNotEmpty(@NonNull T collection) {
    // if (collection.isEmpty()) {
    //     throw new IllegalArgumentException("Must not be empty.");
    // }
    // return collection;
    // }
}

