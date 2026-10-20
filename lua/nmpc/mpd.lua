local M = {}
local mpd = require("nmpc.config").config.mpd

-- SPECIFY COMMANDS --
local send_command

-- commands: playlistinfo, next, prev, play, volume $n,

function M.list_all(callback)
	send_command("listallinfo", function (error, response)
		if error then
			callback(error, nil)
			return
		end

		if not response then
			callback("Empty response from MPD", nil)
			return
		end

		-- format = { artist, title, time, id }
		local song_list = {}
		local song = {}

		for line in response:gmatch("[^\n]+") do
			local file = line:match("^file: (.*)$")
			local artist = line:match("^Artist: (.*)$")
			local title = line:match("^Title: (.*)$")

			if file then
				song.file = file
			end
			if artist then
				song.artist = artist
			end
			if title then
				song.title = title
				table.insert(song_list, song)
				song = {}
			end
		end

		callback(nil, song_list)
	end)
end

---Handles and formats playlistinfo command
---@param callback function(error, response)? response holds formatted data
function M.list_queue(callback)
	send_command("playlistinfo", function (error, response)
		if error then
			callback(error, nil)
			return
		end

		if not response then
			callback("Empty response from MPD", nil)
			return
		end

		-- format = { artist, title, time, id }
		local song_list = {}
		local song = {}

		for line in response:gmatch("[^\n]+") do
			local artist = line:match("^Artist: (.*)$")
			local title = line:match("^Title: (.*)$")
			local duration = line:match("^duration: (.*)$")
			local id = line:match("^Id: (.*)$")

			if artist then
				song.artist = artist
			end
			if title then
				song.title = title
			end
			if duration then
				song.time = duration
			end
			if id then
				song.id = id
				table.insert(song_list, song)
				song = {}
			end
		end

		callback(nil, song_list)
	end)
end

function M.play(id, callback)
	send_command("playid " .. id, function (error, _)
		callback(error)
	end)
end

function M.stop(callback)
	send_command("stop", function (error, _)
		callback(error)
	end)
end

---Increments volume +n/-n
---
---@param n integer? signed int for inc/dec volume
---@param callback function(error, response)? response holds int
function M.change_volume(n, callback)
	send_command("status", function (error, response)
		if error then
			callback(error, nil)
			return
		end

		if not response then
			callback("Couldn't get output from mpd status", nil)
			return
		end

		local volume
		for line in response:gmatch("[^\n]+") do
			volume = line:match("^volume: (.*)$")

			if volume then
				break
			end
		end

		if not volume then
			callback("Couldn't parse volume", nil)
			return
		end

		local new_volume = math.max(0, math.min(100, tonumber(volume) + n))
		send_command("setvol " .. new_volume, function (volume_error, volume_response)
			if volume_error then
				callback(volume_error, volume_response)
				return
			end

			callback(nil, tostring(new_volume))
		end)
	end)
end

---Connect, send one command, return responce or error
---@param command string? must be valid MPD command: https://mpd.readthedocs.io/en/latest/protocol.html
---@param callback function(response)? required for async nature of uv.net_tcp
send_command = function (command, callback)
	local socket, tcp_error = vim.uv.new_tcp()
	local response_buffer = ""
	local response = false
	local exit = false

	if not socket then
		vim.schedule(function ()
			callback("Failed to create socket: " .. tostring(tcp_error), nil)
		end)
		return
	end

	-- standard + graceful handler
	local function error_handle(err, buf)
		if exit then
			return
		end
		exit = true

		if not socket:is_closing() then
			socket:read_stop()
			-- defer close, failed before
			vim.schedule(function ()
				socket:close()
			end)
		end

		vim.schedule(function ()
			callback(err, buf)
		end)
	end

	socket:connect(mpd.bind_to_address, mpd.port, function (error)
		if error then
			error_handle("Connection failed: " .. error)
			return
		end

		-- listen for incoming output from the server
		socket:read_start(function (read_error, data)
			if read_error then
				error_handle("Read failed: " .. read_error)
				return
			end

			if not data then
				-- EOF so close
				error_handle("Connection closed before response completed")
				return
			end

			response_buffer = response_buffer .. data

			-- wait for initial response
			if not response then
				local newline = response_buffer:find("\n")
				if not newline then
					return
				end

				local resp_check = response_buffer:sub(1, newline - 1)
				if not resp_check:match("^OK MPD ") then
					error_handle("Invalid MPD Response: " .. resp_check)
					return
				end

				response = true
				response_buffer = response_buffer:sub(newline + 1)

				socket:write(command .. "\n", function (write_error)
					if write_error then
						error_handle("Write failed: " .. write_error)
					end
				end)
			end

			-- wait for command terminator
            if response_buffer:match("\nOK\n$")
                or response_buffer:match("^OK\n$")
                or response_buffer:match("\nACK [^\n]*\n$")
                or response_buffer:match("^ACK [^\n]*\n$")
            then
                error_handle(nil, response_buffer)
            end
		end)
	end)

end

return M
