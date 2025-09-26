# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy

# 保留 Dart 侧 HTTP 引擎
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.util.** { *; }

# 保留 OkHttp 网络栈（Flutter 内部使用）
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# 保留 Java 网络/DNS 相关
-keep class java.net.** { *; }
-keep class javax.net.ssl.** { *; }
-keep class sun.net.** { *; }
-dontwarn java.net.**
-dontwarn javax.net.**
-dontwarn sun.net.**

# 保留 Dart 的 io 库底层
-keep class dart.io.** { *; }