local M = {}

function M.pad_string(str, max, align)
    max = math.max(0, math.floor(tonumber(max) or 0))
    align = align or "left"

    -- normalize whitespace that has no stable display width
    str = tostring(str):gsub("[\t\r\n]", " ")

    -- truncate by walking utf8 characters and summing display width
    local width = 0
    local out = {}
    for ch in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local w = vim.api.nvim_strwidth(ch)
        if width + w > max then
            break
        end
        width = width + w
        out[#out + 1] = ch
    end
    str = table.concat(out)

    local padding = max - width

    if align == "right" then
        return string.rep(" ", padding) .. str
    elseif align == "center" then
        local left = math.floor(padding / 2)
        return string.rep(" ", left) .. str .. string.rep(" ", padding - left)
    end

    return str .. string.rep(" ", padding)
end

return M
