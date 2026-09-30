# Hầm Ngục Tu Tiên — báo cáo bản thử

Bản `0.1.0-dev`, nhánh `codex/ham-nguc-tu-tien`; thiết kế đã duyệt ngày 2026-09-30. Triển khai trong mod mới, không sửa các mod chơi hiện có hay nguồn Solo local. Chưa merge/push/đưa lên Workshop.

## Bằng chứng

- 32/32 test Lua; 73 Lua files kiểm tra syntax; 51 Asset literal đều tồn tại trong mod hoặc game; dependency checker PASS.
- DST build747465: spawn19 prefab, thực thi13 nhóm state boss, Solo tắt.
- 18 shard với seed khác nhau: mỗi tổ hợp small/huge × Forest-only/Forest+Caves có3 seed. Caves không có manager/arena; cặp shard nối được; Forest có đúng một exit và điểm cổng mainland hợp lệ, đường đi gần exit thông.
- Tu Tiên18.1.0 thật: đủ Linh Thạch, xác minh OnUse→onusefn(inst,doer). Entry/reward/death-recovery/cleanup chạy cùng Nyx, Thần Khí, Công Trình và Thành Tựu.
- Save khi trận đang đánh → restart: hủy lượt, dọn quái, giữ đúng một rương thu hồi kèm đồ/owner. Merge5 thưởng+7 cá nhân → split+cleanup vẫn còn12 đơn vị.
- Fresh review bằng gpt-6-astra: hai Important đã sửa và có test RED→GREEN, không có Critical được phát hiện. Không dùng review làm thay thế kiểm chứng gameplay.

Seed, tên log và SHA-256 nằm trong `HamNgucTuTien/tests/qa-results.json`. Log và ledger được lưu ở `dist/HamNgucTuTien-qa-20260930.zip`. Bản cài nằm ở `dist/HamNgucTuTien-0.1.0-dev.zip`; loại các script QA khỏi bản cài.

## Quyết định khi triển khai và giới hạn

1. Worktree riêng tạo được nhưng sandbox không cho ghi: dùng nhánh riêng và thư mục mod mới trong checkout hiện tại, giữ mọi thay đổi không thuộc tác vụ. Worktree không dùng đã archive. Đổi lại không có cách ly thư mục hoàn toàn.
2. Git Bash helpers của skill lỗi signal pipe: giữ ledger/task evidence bằng PowerShell và file tương đương. Chi phí là bookkeeping thủ công; ledger có trong gói QA.
3. Dời ma trận kiểm chứng rộng sau bước tích hợp code để thấy đủ dependency; checkpoint lớn hơn nhưng chỉ chạy trên cluster thử. Ma trận engine hiện đã đạt; client vẫn chờ nghiệm thu.
4. Giữ bank/build animation và stategraph obfuscated của nguồn để giữ timing. Đổi lại code chiêu khó bảo trì và hình ảnh cần so sánh trực tiếp.
5. Thu hồi entity gốc, dùng save của container DST. Ba lô không thể đặt trong container nằm trên đất tại cổng, giữ toàn bộ đồ bên trong; đổi lại ba lô vẫn chịu môi trường như đồ thả bình thường. Rương dùng chung, owner id chỉ là metadata.
6. Stack lẫn đồ cá nhân và thưởng được giữ nguyên toàn bộ để tránh xóa phần của người chơi. Không tách định lượng nguồn của từng đơn vị; phần thưởng cùng stack cũng được giữ.
7. Dependency checker + kiểm tra73 file Lua + engine scenarios thay file `boss_contract.lua` dự kiến. Đường động ngoài các scenario đã thực thi vẫn cần playtest.
8. Giữ nhánh local và đóng bản dev vì chưa có yêu cầu merge/push/publish. Chưa gọi đây là bản phát hành ổn định.

Reviewer không phán quyết hình ảnh remote client, parity animation, chiến đấu nhiều người và cân bằng kinh tế. Các phần này vẫn là tiêu chí nghiệm thu mở; test headless chỉ xác minh những ca nêu trên. Hover tooltip hiện có hạng/làn nhưng chưa có gợi ý số người như nguồn — mục nhỏ đã hoãn, không chặn thử mod.

## Việc cần chơi thử

Xem `HamNgucTuTien/tests/manual-checklist.md`: hai client thật, reconnect người offline, hoạt ảnh/minimap, đủ2–10 làn và cả ba boss sát tường, skill teleport/revive/companion trực tiếp, thời gian clear và loot/giờ. Giữ tên dev cho đến khi các ca này được nghiệm thu.
