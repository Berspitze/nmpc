---@class SongEntry
---@field title string
---@field artist string
---@field album string
---@field genre string
---@field duration string
---@field file string
---@field id string
---@field search fun(self: SongEntry, query: string): boolean
local SongEntry = {}

---Fields that are searchable
local SEARCH_FIELDS = {
	"title",
	"artist",
	"album",
	"genre",
}

---Ensures unified data, c base
---@param data table created in mpd
---@return SongEntry
function SongEntry.new(data)
	local self = setmetatable({}, SongEntry)
	self.title = data.title or ""
	self.artist = data.artist or ""
	self.album = data.album or ""
	self.genre = data.genre or ""
	self.duration = data.duration or ""
	self.file = data.file or ""
	self.id = data.id or ""

	return self
end

---Splits a string into lowercase words for search
---@param str string
---@return string[]
local function words(str)
	local out = {}
	for w in str:lower():gmatch("%S+") do
		out[#out + 1] = w
	end

	return out
end

---Returns true if every word every word matches a substring of SongEntry
---metadata
---@param query string some string that is found within a word
---@return boolean
function SongEntry:search(query)
	local query_words = words(query)
	if #query_words == 0 then
		return true -- no query = always true
	end

	-- collect every word from searchable fields
	local hay_stack = {} -- dumb search
	for _, field in ipairs(SEARCH_FIELDS) do
		for _, word in ipairs(words(self[field] or "")) do
			hay_stack[#hay_stack+1] = word
		end
	end

	-- each word in query matches somewhere
	for _, query in ipairs(query_words) do
		local needle_found = false
		for _, hay in ipairs(hay_stack) do
			if hay:find(query, 1, true) then
				found = true
				break
			end
		end

		if not found then
			return false
		end
	end

	-- found each query sub-phrase
	return true
end

return SongEntry
