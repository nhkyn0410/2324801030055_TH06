# Hướng dẫn cấu hình Firebase cho TH06 Music

Ứng dụng chạy được ngay ở chế độ khách: xem danh sách, tìm kiếm, phát nhạc, lời bài hát, phát nền. Các tính năng cần tài khoản gồm đăng nhập, thích bài hát, playlist cá nhân và thống kê nghe nhạc chỉ hoạt động sau khi bạn làm xong các bước dưới đây.

Thời gian thực hiện khoảng 10 phút. Toàn bộ dùng gói miễn phí Spark, không cần thẻ thanh toán.

## 1. Dữ liệu được lưu ở đâu

| Loại dữ liệu | Nơi lưu | Ghi chú |
| --- | --- | --- |
| File nhạc mp3 | Không lưu | Stream trực tiếp từ Audius API qua URL |
| Tài khoản | Firebase Authentication | Đăng nhập bằng Email và mật khẩu, hoặc bằng tài khoản Google |
| Bài hát đã thích, playlist, thống kê | Cloud Firestore | Mỗi người dùng một nhánh riêng |

Cấu trúc Firestore mà ứng dụng tự tạo khi ghi dữ liệu, bạn không cần tạo tay:

```
users/{uid}
    displayName, email, createdAt

users/{uid}/likes/{songId}
    id, title, artist, artworkSmall, artworkLarge,
    durationSeconds, genre, playCount, likedAt

users/{uid}/playlists/{playlistId}
    name, createdAt, updatedAt
    songs: mảng các bài hát, mỗi phần tử có cùng các trường như ở likes

users/{uid}/plays/{songId}
    song: thông tin bài hát
    count: số lượt phát
    seconds: tổng số giây đã nghe
    lastPlayedAt

users/{uid}/daily/{yyyy-MM-dd}
    date, seconds, plays
```

Trong đó `uid` là mã người dùng do Firebase Authentication cấp, `songId` là mã bài hát của Audius.

## 2. Tạo project Firebase

1. Mở https://console.firebase.google.com và đăng nhập tài khoản Google.
2. Nhấn Create a project (hoặc Add project).
3. Nhập tên project, ví dụ `th06-music`, rồi nhấn Continue.
4. Ở bước Google Analytics, tắt công tắc Enable Google Analytics vì bài này không dùng.
5. Nhấn Create project, chờ khoảng nửa phút rồi nhấn Continue.

## 3. Đăng ký ứng dụng Android và lấy google-services.json

1. Tại trang Project Overview, nhấn biểu tượng Android để thêm ứng dụng.
2. Ô Android package name nhập chính xác:

   ```
   com.example.th06_2324801030055
   ```

   Giá trị này phải trùng với `applicationId` trong file `android/app/build.gradle.kts`.
3. Ô App nickname nhập tùy ý, ví dụ TH06 Music. Ô SHA-1 để trống.
4. Nhấn Register app.
5. Nhấn Download google-services.json.
6. Chép file vừa tải vào thư mục `android/app` của project, đường dẫn cuối cùng phải là:

   ```
   android/app/google-services.json
   ```

7. Các bước Add Firebase SDK tiếp theo trên Console bạn bỏ qua, chỉ cần nhấn Next rồi Continue to console. Project đã khai báo sẵn plugin Google services trong `android/settings.gradle.kts` và `android/app/build.gradle.kts`, plugin sẽ tự kích hoạt khi thấy file `google-services.json`.

## 4. Bật đăng nhập bằng Email và mật khẩu

1. Ở menu bên trái chọn Build, rồi chọn Authentication.
2. Nhấn Get started.
3. Mở tab Sign-in method, chọn Email/Password.
4. Bật công tắc Enable ở dòng đầu tiên. Dòng Email link để nguyên trạng thái tắt.
5. Nhấn Save.

## 5. Tạo Cloud Firestore

1. Ở menu bên trái chọn Build, rồi chọn Firestore Database.
2. Nhấn Create database.
3. Chọn phiên bản Standard edition.
4. Database ID để nguyên là `(default)`. Location chọn `asia-southeast1 (Singapore)` để gần Việt Nam nhất. Lưu ý vị trí này không đổi được sau khi tạo.
5. Chọn Start in production mode rồi nhấn Create.

## 6. Thiết lập Rules bảo mật

1. Trong trang Firestore Database, mở tab Rules.
2. Xóa nội dung cũ, dán toàn bộ nội dung file `firestore.rules` ở thư mục gốc của project:

   ```
   rules_version = '2';

   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

3. Nhấn Publish.

Ý nghĩa: chỉ người đã đăng nhập mới đọc và ghi được, và mỗi người chỉ truy cập được nhánh `users/{uid}` của chính mình. Người khác không xem được playlist hay lịch sử nghe của bạn.

## 7. Chạy lại ứng dụng

Sau khi chép `google-services.json` cần build lại hoàn toàn, hot reload là không đủ.

```bash
flutter run
```

Nếu ứng dụng vẫn báo Firebase chưa được cấu hình, chạy lệnh sau rồi chạy lại:

```bash
flutter clean
```

## 8. Kiểm tra dữ liệu trên Console

| Thao tác trong ứng dụng | Nơi xem trên Firebase Console |
| --- | --- |
| Đăng ký tài khoản ở tab Tài khoản | Authentication, tab Users |
| Nhấn trái tim ở một bài hát | Firestore, `users/{uid}/likes` |
| Tạo playlist, thêm bài vào playlist | Firestore, `users/{uid}/playlists` |
| Nghe một bài hơn 10 giây | Firestore, `users/{uid}/plays` và `users/{uid}/daily` |

Thống kê được ghi mỗi 20 giây nghe nhạc, hoặc ngay khi bạn tạm dừng hay chuyển bài. Một lượt phát được tính khi nghe liên tục một bài từ 10 giây trở lên.

Đăng nhập cùng tài khoản trên máy khác sẽ thấy đúng các bài đã thích, playlist và thống kê.

## 9. Lỗi thường gặp

| Hiện tượng | Nguyên nhân và cách xử lý |
| --- | --- |
| Ứng dụng báo Firebase chưa được cấu hình | Thiếu file `android/app/google-services.json` hoặc đặt sai thư mục. Chép lại rồi build lại |
| Build lỗi No matching client found for package name | Package name khai báo trên Console khác `com.example.th06_2324801030055`. Thêm lại app Android với đúng tên |
| Báo phương thức đăng nhập này chưa được bật | Chưa bật Email/Password ở mục 4 hoặc chưa bật Google ở mục 10 |
| Cửa sổ chọn tài khoản Google tự đóng, báo đăng nhập đã bị hủy | Thiếu hoặc sai SHA-1 của máy đang build. Xem bước 2 mục 10 |
| Báo cấu hình đăng nhập Google chưa đúng | File `google-services.json` tải trước khi bật Google. Tải lại theo bước 3 mục 10 |
| Báo Firestore từ chối truy cập | Chưa Publish Rules ở mục 6 |
| Đăng ký được nhưng không thấy dữ liệu trong Firestore | Chưa tạo database ở mục 5 |

## 10. Đăng nhập bằng Google

Nút Tiếp tục với Google đã có sẵn ở màn hình đăng nhập. Nút chỉ hoạt động sau khi bạn làm đủ ba bước dưới đây, sau khi đã xong mục 2 và mục 3.

1. Bật nhà cung cấp Google. Vào Build, chọn Authentication, mở tab Sign-in method, nhấn Add new provider, chọn Google, bật Enable, chọn Support email rồi nhấn Save.
2. Khai báo dấu vân tay của khóa ký. Vào Project settings bằng biểu tượng bánh răng, kéo xuống mục Your apps, chọn app Android, nhấn Add fingerprint và dán lần lượt SHA-1 rồi SHA-256. Lấy hai giá trị này bằng lệnh sau, đọc ở khối `Variant: debug`:

   ```bash
   ./android/gradlew -p android signingReport -q
   ```

   Khóa debug trên máy đã dùng để viết bài này có giá trị:

   ```
   SHA-1    A4:3B:BE:D0:62:E4:04:63:E2:9E:65:D8:14:D5:7B:73:36:F2:7F:D2
   SHA-256  B9:70:DD:24:CC:1A:8F:4B:8F:B5:C3:7B:CF:63:84:0C:01:B9:7F:0E:03:2F:3B:B9:F3:ED:A1:53:BB:C0:6B:74
   ```

3. Tải lại `google-services.json` ở chính trang Project settings đó và chép đè vào `android/app/google-services.json`. File tải trước khi bật Google thiếu mục OAuth client nên đăng nhập sẽ lỗi.

Sau đó build lại bằng `flutter run`.

Lưu ý khi demo:

- Mỗi máy tính có khóa debug riêng. Nếu build trên máy khác, chạy lại lệnh ở bước 2 trên máy đó và thêm SHA-1 mới vào Console. Không cần tải lại `google-services.json` khi chỉ thêm SHA-1.
- Máy ảo hoặc điện thoại phải có Google Play services và đã thêm ít nhất một tài khoản Google trong Settings.
- Rules của Firestore không phải đổi vì vẫn phân quyền theo `uid`.

## 11. Tùy chọn: tự lưu file mp3 bằng Firebase Storage

Phần này không bắt buộc và ứng dụng hiện chưa cài đặt, chỉ ghi lại để bạn tham khảo nếu muốn mở rộng theo gợi ý của đề.

1. Firebase Storage hiện yêu cầu nâng project lên gói Blaze, cần gắn thẻ thanh toán. Mức dùng nhỏ của bài tập vẫn nằm trong hạn mức miễn phí.
2. Vào Build, chọn Storage, nhấn Get started, chọn cùng vị trí với Firestore.
3. Tạo thư mục `songs` và tải file mp3 lên. Mở từng file để sao chép Download URL.
4. Tạo collection `songs` trong Firestore, mỗi document gồm các trường `title`, `artist`, `artworkUrl`, `audioUrl`, `durationSeconds`.
5. Trong code, viết thêm một lớp đọc collection `songs` trả về `List<Song>` tương tự `lib/services/audius_api.dart`, và cho `Song` giữ thêm trường `audioUrl` để `PlayerProvider` phát trực tiếp URL đó.
