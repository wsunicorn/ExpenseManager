# Giữ lại các lớp mà R8 không tự thấy được vì chúng chỉ được gọi qua reflection
# hoặc từ phía Android chứ không từ Dart.

# Widget màn hình chính — AndroidManifest gọi tên lớp bằng chuỗi, R8 không
# lần ra được. Bị thu nhỏ mất thì widget biến mất khỏi danh sách của launcher.
-keep class com.nnlan.so_thu_chi.BalanceWidgetProvider { *; }
-keep class es.antonborri.home_widget.** { *; }

# Thông báo cục bộ: plugin dùng reflection để khôi phục lịch sau khi khởi động
# lại máy.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# sqlite3 nạp thư viện native qua JNI.
-keep class com.tekartik.** { *; }

# Bỏ qua cảnh báo về lớp chỉ có ở nền khác — chúng không bao giờ được gọi.
-dontwarn java.awt.**
-dontwarn javax.swing.**
