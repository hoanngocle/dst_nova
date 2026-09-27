-- Vietnamese text for Super Wall DST by DYC. Keep the original prefab IDs.
return function(english)
    local result = {}
    for key, value in pairs(english) do
        if type(value) == "table" then
            local entry = {}
            for field, text in pairs(value) do
                entry[field] = text
            end
            result[key] = entry
        else
            result[key] = value
        end
    end

    local names = {
        wooddoor = "Cửa Gỗ Siêu Cấp", woodwall = "Tường Gỗ Siêu Cấp",
        haydoor = "Cửa Cỏ Siêu Cấp", haywall = "Tường Cỏ Siêu Cấp",
        stonedoor = "Cửa Đá Siêu Cấp", stonewall = "Tường Đá Siêu Cấp",
        ruindoor = "Cửa Thulecite Siêu Cấp", ruinwall = "Tường Thulecite Siêu Cấp",
        limestonedoor = "Cửa Đá Vôi Siêu Cấp", limestonewall = "Tường Đá Vôi Siêu Cấp",
        moonrockdoor = "Cửa Đá Mặt Trăng Siêu Cấp", moonrockwall = "Tường Đá Mặt Trăng Siêu Cấp",
        icedoor = "Cửa Băng Siêu Cấp", icewall = "Tường Băng Siêu Cấp",
        seadoor = "Cửa Biển Siêu Cấp", seawall = "Tường Biển Siêu Cấp",
        pigruindoor = "Cửa Cổ Đại Siêu Cấp", pigruinwall = "Tường Cổ Đại Siêu Cấp",
        hedgedoor = "Cửa Hàng Rào Cây Siêu Cấp", hedge = "Hàng Rào Cây Siêu Cấp",
        fence = "Hàng Rào Gỗ Siêu Cấp", fencegate = "Cổng Hàng Rào Gỗ Siêu Cấp",
        parkfence = "Hàng Rào Công Viên Siêu Cấp", parkdoor = "Cửa Công Viên Siêu Cấp",
        parkgate = "Cổng Công Viên Siêu Cấp", wallbuilder = "Dụng Cụ Xây Tường Nhanh",
    }
    for key, name in pairs(names) do
        local entry = result[key] or {}
        result[key] = entry
        entry.name = name
        if key == "wallbuilder" then
            entry.des = "Xây nhanh một tổ hợp tường và cửa."
            entry.char_des = "Ta có thể xây cả một mê cung."
        elseif key:find("door") or key:find("gate") then
            entry.des = "Tự mở khi người được phép đến gần."
            entry.char_des = "Một cánh cửa thật tiện lợi."
        else
            entry.des = "Công trình phòng thủ vững chắc."
            entry.char_des = "Căn cứ của ta an toàn hơn rồi."
        end
    end

    local messages = {
        helpcmd = "[Lệnh trò chuyện Super Wall]\nAdminMode: Bật/tắt chế độ quản trị.\nAdd + số người chơi: Thêm người được phép.\nRemove + số người chơi: Xóa quyền.\nList: Xem danh sách được phép.",
        cmdincorrect = "Lệnh không hợp lệ. Gõ '-sw help' để xem trợ giúp.",
        adminhelpcmd = "[Lệnh quản trị Super Wall]\nLanguage: Đổi ngôn ngữ.\nOwnership + số: Đổi quyền sử dụng (0=công khai, 1=người được phép).\nDamage + số: Đổi sát thương phản lại.\nCompanion + true/false: Bật/tắt mở cửa cho thú đồng hành.",
        admincmdincorrect = "Lệnh quản trị không hợp lệ. Gõ '-sw help admin' để xem trợ giúp.",
        adminmodeon = "Đã bật chế độ quản trị Super Wall.",
        adminmodeoff = "Đã tắt chế độ quản trị Super Wall.",
        adminmodehint = "Hãy bật chế độ quản trị trước.",
        admindenied = "Bạn không có quyền quản trị.",
        message = "Thông báo",
        fastbuild = "[Xây nhanh] Chuột giữa hoặc F5: xoay; cuộn chuột hoặc F1/F2: đổi mẫu; F3/F4: đổi độ cao; Alt + chuột phải: phá bỏ.",
        singlewallbuild = "F3/F4: đổi độ cao.",
        singlewallbuild_2 = "F3/F4: đổi màu.",
        rotation = "Góc xoay", degrees = "Độ",
        heightadjustment = "Điều chỉnh độ cao", heightadjustment_2 = "Đổi màu",
        fencealthint = "Giữ Alt để tắt xoay tự động.",
        readytobuild = "Đã đủ vật liệu!",
        insufficientwallitem = "Không đủ vật liệu xây tường!",
        requiredmaterials = "Vật liệu cần có:",
        buildingcomplete1 = "Đã xây xong!",
        buildingcomplete2 = "Một phần công trình chưa hoàn thành.",
        buildingcomplete3 = "Xây thất bại. Kiểm tra vật liệu và vật cản.",
        walldestroyed1 = "Đã phá xong!", walldestroyed2 = "Không có gì để phá.",
        wallheightchanged1 = "Đã đổi độ cao tường!", wallheightchanged2 = "Không có tường để đổi.",
        freebuildmodeon = "Super Wall: bật xây miễn phí cho mọi người chơi.",
        freebuildmodeoff = "Super Wall: tắt xây miễn phí.",
        str0 = "tường", str1 = "cửa", str0_2 = "hàng rào", str1_2 = "cổng",
        str2 = "Chủ sở hữu đã rời thế giới này.", str3 = "Công trình này ",
        str4 = "là của tôi!", str5 = " có chủ sở hữu là ", str6 = "!",
        str7 = " giờ có thể dùng ", str8 = " của tôi", str9 = " của ",
        str10 = "tôi", str11 = "tường và cửa siêu cấp!",
        str12 = "Tôi không được phép làm vậy.",
        str13 = " đang cố phá ", str13_2 = " đang cố khóa hoặc mở khóa ",
        str14 = "nhưng", str15 = "Tôi có thể dùng nó!",
        str16 = " hiện không thể dùng ",
        str17 = "Không cần làm vậy; tường và cửa đang dùng chung.",
        str18 = "Không cần tự thêm hoặc xóa chính mình.",
        str19 = "Không tìm thấy người chơi.", str20 = " muốn dùng ",
        str21 = "Nhấn Y hoặc U rồi nhập '-sw a ",
        str22 = "' để thêm người đó vào danh sách được phép.",
        str23 = "Người chơi", str24 = "đã có quyền", str25 = "chưa có quyền",
        str26 = "[Danh sách người được phép]", str27 = "Đã khóa!", str28 = "Đã mở khóa!",
    }
    for key, value in pairs(messages) do
        result[key] = value
    end
    return result
end
