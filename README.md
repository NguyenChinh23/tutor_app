# Ứng dụng Tìm kiếm Gia sư cho Học viên (Flutter Mobile Application)

Ứng dụng Tìm kiếm Gia sư cho Học viên là một ứng dụng di động được phát triển bằng Flutter, hỗ trợ học viên dễ dàng tìm gia sư phù hợp, đặt lịch học và theo dõi tiến trình học tập.
Ứng dụng hỗ trợ hai hình thức học: online và offline, phù hợp với mọi nhu cầu cá nhân.

Các tính năng chính:
 Tính năng chính
 Dành cho Học viên
1. Quản lý tài khoản

Đăng ký / đăng nhập bằng email.

Chỉnh sửa thông tin cá nhân, số điện thoại, địa chỉ, mục tiêu học.

2. Tìm kiếm và xem gia sư

Tìm kiếm theo môn học, cấp độ, giá dạy, hình thức học.

Xem chi tiết gia sư: kinh nghiệm, mô tả, lịch rảnh, đánh giá, giá học.

Bộ lọc thông minh giúp nhanh chóng tìm đúng gia sư.

3. Đặt lịch học

Đặt buổi học đơn hoặc gói nhiều buổi.

Chọn thời gian, hình thức học và ghi chú.

Nhận thông báo khi gia sư chấp nhận hoặc từ chối.

4. Quản lý lịch học

Xem lịch học sắp tới.

Xem lịch sử học (đã hoàn thành / bị hủy).

Không thể đánh giá buổi học bị hủy.

5. Đánh giá – Nhận xét

Đánh giá sao (1–5) sau khi hoàn thành buổi học.

Gửi nhận xét chi tiết giúp cải thiện chất lượng giảng dạy.

6. Thông báo realtime

Cập nhật trạng thái đặt lịch, đánh giá, thông tin buổi học.

Thông báo hoạt động nhờ Firestore Realtime Stream (không sử dụng FCM).

 Dành cho Gia sư
1. Gửi hồ sơ đăng ký

Điền thông tin giảng dạy, môn học, mức giá, kinh nghiệm.

Chờ quản trị viên xét duyệt.

2. Quản lý yêu cầu đặt lịch

Nhận thông báo khi có yêu cầu mới.

Chấp nhận hoặc từ chối yêu cầu.

3. Quản lý lịch dạy

Xem lịch buổi học sắp tới.

Xem lịch sử buổi dạy và đánh giá học viên.

4. Xem đánh giá từ học viên

Theo dõi phản hồi để cải thiện kỹ năng giảng dạy.

 Dành cho Quản trị viên
1. Quản lý hồ sơ gia sư

Xét duyệt / từ chối hồ sơ trở thành gia sư.

Đảm bảo gia sư đạt tiêu chuẩn trước khi hoạt động.

2. Quản lý người dùng

Xem toàn bộ học viên, gia sư, admin.

Xóa hoặc vô hiệu hóa tài khoản khi cần.

3. Quản lý hệ thống

Giám sát booking.

Xử lý các trường hợp ngoại lệ từ học viên hoặc gia sư.

Kiến trúc dự án

Ứng dụng áp dụng kiến trúc Clean Architecture rút gọn kết hợp MVVM
Vai trò từng phần

Model: đại diện dữ liệu (User, Tutor, Booking, Notification,…)

Repository: xử lý tương tác Firestore & Firebase Auth

Provider (ViewModel): quản lý trạng thái + nghiệp vụ

UI (View): hiển thị thông tin từ provider

Công nghệ sử dụng

Flutter & Dart

Firebase Authentication

Cloud Firestore

Provider (quản lý trạng thái MVVM)

Intl — định dạng thời gian

Base64 avatar cho thông báo (không dùng Firebase Storage trong module thông báo)
