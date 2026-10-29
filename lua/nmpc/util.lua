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
---@return table|nil of lengths = #opts
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

---@param entries SongEntry[]
---@param query string
---@param field string
---@return SongEntry[]
function M.binary_search_all(entries, query, field)
    local results = {}
    local target = query:lower()
    local low, high = 1, #entries

    -- Find first entry >= target
    while low <= high do
        local mid = math.floor((low + high) / 2)

        if entries[mid][field]:lower() < target then
            low = mid + 1
        else
            high = mid - 1
        end
    end

    -- Collect exact matches
    for i = low, #entries do
        local value = entries[i][field]:lower()

        if value ~= target then
            break
        end

        table.insert(results, entries[i])
    end

    return results
end


---Returns the index of a unique SongEntry matching title and artist
---@param entries SongEntry[]
---@param query string format: "title - artist"
---@return integer|nil index
function M.binary_search_index(entries, query)
    local title, artist = query:match("^(.-)%s+%-%s+(.+)$")

    if not title or not artist then
        vim.notify(
            'Expected query format: "title - artist"',
            vim.log.levels.WARN
        )
        return nil
    end

    title = title:lower()
    artist = artist:lower()

    local low, high = 1, #entries
    local first_match = nil

    -- Find the first entry matching the title.
    while low <= high do
        local mid = math.floor((low + high) / 2)
        local entry_title = (entries[mid].title or ""):lower()

        if entry_title < title then
            low = mid + 1
        else
            if entry_title == title then
                first_match = mid
            end
            high = mid - 1
        end
    end

    if not first_match then
        return nil
    end

    -- Scan entries sharing the title and match the artist.
    local match_index = nil

    for i = first_match, #entries do
        local entry = entries[i]

        if (entry.title or ""):lower() ~= title then
            break
        end

        if (entry.artist or ""):lower() == artist then
            if match_index then
                vim.notify(
                    ("Multiple entries found for '%s - %s'"):format(
                        entry.title, entry.artist
                    ),
                    vim.log.levels.WARN
                )
                return nil
            end

            match_index = i
        end
    end

    return match_index
end

---Returns geometry of window
---@class Geometry
---@field width integer
---@field height integer
---@field x integer
---@field y integer
---@return Geometry
function M.window_geometry()
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.5)

	return {
		width = width,
		height = height,
		x = math.floor((vim.o.columns - width) / 2),
		y = math.floor((vim.o.lines - height) / 2)
	}
end

-- validation
function M.valid_buffer(b) return b and vim.api.nvim_buf_is_valid(b) end
function M.valid_window(w) return w and vim.api.nvim_win_is_valid(w) end


return M


