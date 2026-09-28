local pages = {}

pages.PAGE_SIZE = 14

function pages.PageCount(category)
    return math.max(1, math.ceil(category.count / pages.PAGE_SIZE))
end

function pages.Range(category, requested_page)
    local total = pages.PageCount(category)
    local page = math.max(1, math.min(total, math.floor(tonumber(requested_page) or 1)))
    local offset = (page - 1) * pages.PAGE_SIZE
    return category.start + offset, math.min(pages.PAGE_SIZE, category.count - offset), page, total
end

return pages
