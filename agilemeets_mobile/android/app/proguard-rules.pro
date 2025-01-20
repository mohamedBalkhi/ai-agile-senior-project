# Keep OkHttp and its dependencies
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Joda Time
-dontwarn org.joda.time.**
-keep class org.joda.time.** { *; }

# Keep Google API Client classes (using OkHttp transport)
-dontwarn com.google.api.client.**
-keep class com.google.api.client.** { *; }

# Keep previously added rules for other dependencies
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }
-dontwarn javax.annotation.**
-keep class javax.annotation.** { *; }
-keep class com.google.crypto.tink.** { *; }