local M = {}

---Pads/removes characters to max with alignment
---@param str string
---@param max uinteger target character length
---@param align string "left" "right" "center"
---@return string of max characters
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

function M.search(query, songs)
	-- terms def by space
	local terms = {}
	for term in query:lower():gmatch("%S+") do
		terms[#terms + 1] = term
	end
	if #terms == 0 then
		return songs
	end

	-- matches terms with potential substr
	local results = {}
	for _, song in ipairs(songs) do
		local haystack = (song.title .. " " .. song.artist):lower()
		local ok = true

		for _, term in ipairs(terms) do
			if not haystack:find(term, 1, true) then
				ok = false
				break
			end
		end

		if ok then
			results[#results+1] = song
		end
	end

	return results
end

---Splits a number up by an array of opts, "n%" or n
---@param length integer total length to be divided
---@param opts (string|integer)[] relative or percentage based
---@return table of lengths = #opts
function M.split_length(length, opts)
	local sizes = {}
	local remainder = length
	local percentage_total = 0

	-- calculate fixed + tally up percentages
	for i, item in ipairs(opts) do
		if type(item) == "string" then
			local percent = tonumber(item:match("^(%d+)%%"))
			if not percent then
				return nil
			end
			percentage_total = percentage_total + percent
		elseif type(item) == "number" then
			sizes[i] = item
			remainder = remainder - item
		end
	end

	if remainder < 1 or (percentage_total == 0 and remainder > 0) then
		return nil
	end

	-- calculate residual percentages based off of leftovers
	for i, item in ipairs(opts) do
		if type(item) == "string" then
			local percent = tonumber(item:match("^(%d+)%%"))
			sizes[i] = percent / percentage_total * remainder
		end
	end

	return sizes
end


-- validation
function M.valid_buffer(b) return b and vim.api.nvim_buf_is_valid(b) end
function M.valid_window(w) return w and vim.api.nvim_win_is_valid(w) end


return M


