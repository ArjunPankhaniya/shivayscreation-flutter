# Keep Razorpay package
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Firebase and Play Services fixes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin metadata compatibility
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }
-keep class kotlin.jvm.internal.** { *; }
-dontwarn kotlin.**

# Keep Protobuf classes
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Additional Keep Rules (Fixes Unresolved Classes)
-keep class android.support.** { *; }
-keep class androidx.** { *; }
-dontwarn androidx.**
