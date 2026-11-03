# PvZ Menu (.deb)

1. Mở `Tweak.m`, sửa hàm `Items()`: điền direct link + tên file cần thay.
2. Kiểm tra bundle ID game trong `PvZMenu.plist` (mặc định: com.popcap.ios.PvZ2).
3. Build:
   - Có Theos:  `make package FINALPACKAGE=1`  -> file .deb nằm trong `packages/`
   - Không có Mac: đẩy cả thư mục lên GitHub -> tab Actions -> "Build deb" -> tải artifact.
4. Cài .deb bằng Sileo/Zebra/Filza, mở game, bấm icon tròn để mở menu.

Ghi chú:
- File gốc được sao lưu thành `<tên file>.bak` ở lần thay đầu tiên.
- Sau khi thay file, thoát hẳn game và mở lại.
- Jailbreak rootless: bỏ comment dòng THEOS_PACKAGE_SCHEME trong Makefile.
- Không jailbreak: lấy `PvZMenu.dylib` (trong .deb) và inject vào IPA bằng Sideloadly/ESign.
