-keep class **.zego.** { *; }
# Keep Java beans annotations used by Jackson
-keepclassmembers class * {
    @java.beans.ConstructorProperties <init>(...);
}
-keep class java.beans.** { *; }
-keep class org.w3c.dom.bootstrap.DOMImplementationRegistry { *; }
-dontwarn java.beans.**
-dontwarn org.w3c.dom.bootstrap.**