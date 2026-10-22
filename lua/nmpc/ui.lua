local M = {}
local config = require("nmpc.config")
local mpd = require("nmpc.mpd")
local util = require("nmpc.util")
local pad_string = require("nmpc.util").pad_string

-- stores all songs
local queue = {}
local search = {}
local all_songs = {}

-- forward declare
local choose

function M.queue_window()
	local width  = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.5)
	local x      = math.floor((vim.o.columns - width) / 2)
	local y      = math.floor((vim.o.lines - height) / 2)

	-- buffers for content
	local buffer = vim.api.nvim_create_buf(false, true)
	vim.bo[buffer].bufhidden = "wipe"

	-- fill buffer with queue content
	mpd.list_queue(function (error, response)
		vim.schedule(function ()
			if error then
				vim.notify("List Queue Error: " .. error)
				return
			end
			if not response then
				vim.notify("List queue got no response")
				return
			end

			queue = response

			-- sizes match window_format.sizes
			local sizes = {}
			local fixed_width = 0
			local percent_total = 0

			-- calculate fixed and percentage widths
			for i, item in ipairs(config.config.window_format.sizes) do
				if type(item) == "string" then
					local percent = tonumber(item:match("^(%d+)%%"))
					sizes[i] = percent
					percent_total = percent_total + percent
				else
					sizes[i] = item
					fixed_width = fixed_width + item
				end
			end

			-- distribute remaining width among percent columns
			local available_width = width - fixed_width - (#sizes - 1)
			for i, item in ipairs(config.config.window_format.sizes) do
				if type(item) == "string" then
					sizes[i] = math.floor(available_width * sizes[i] / percent_total)
				end
			end

			-- format each row
			local display_lines = {}

			for i, entry in ipairs(queue) do
				local fmt = {}

				for j, header in ipairs(config.config.window_format.header) do
					fmt[j] = pad_string(
						tostring(entry[header] or ""),
						sizes[j],
						config.config.window_format.alignment[j]
					)
				end

				display_lines[i] = table.concat(fmt, " ")
			end

			-- namespace for coloring
			local queue_ns = vim.api.nvim_create_namespace("nmpc_queue")
			vim.api.nvim_buf_clear_namespace(buffer, queue_ns, 0, -1)

			vim.bo[buffer].modifiable = true
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, display_lines)
			vim.bo[buffer].modifiable = false

			-- TODO: FIX LATER
			-- each column is width bound -> easy coloring
			for row, _ in ipairs(display_lines) do
				local column = 0
				for i, size in ipairs(sizes) do
					local start_column = column
					local end_column = start_column + #pad_string(
						tostring(queue[row][config.config.window_format.header[i]] or ""),
						size,
						config.config.window_format.alignment[i]
					)
					vim.api.nvim_buf_set_extmark(buffer, queue_ns,
						row - 1,
						start_column,
						{
							end_row = row - 1,
							end_col = end_column,
							hl_group = "NmpcHeader" .. i,
						}
					)
					column = end_column + 1
				end
			end
		end)
	end)

	-- draw buffer to window
	local window = vim.api.nvim_open_win(buffer, true, { -- takes focus
		relative = "editor",
		style = "minimal",
		border = "rounded",
		width = width,
		height = height,
		col = x,
		row = y,
		title = " Queue ",
	})
	vim.wo[window].cursorline = true
	config.style_window(window)

	-- keymaps
	vim.keymap.set("n", "<CR>", function ()
		choose(window, buffer)
	end)
	require("nmpc.keybind").setup_queue_window(window, buffer)
end

function M.search_window()
	local width  = math.floor(vim.o.columns * 0.6)
	local input_height = 1
	local result_height = math.floor(vim.o.lines * 0.5) - input_height - 2
	local x      = math.floor((vim.o.columns - width) / 2)
	local y      = math.floor((vim.o.lines - result_height) / 2)

	local input_buffer = vim.api.nvim_create_buf(false, true)
	local result_buffer = vim.api.nvim_create_buf(false, true)
	vim.bo[input_buffer].bufhidden = "wipe"


	-- setup get all songs in mpd
	mpd.list_all(function (error, response)
		vim.schedule(function ()
			if error then
				vim.notify("List All Error: " .. error)
				return
			end
			if not response then
				vim.notify("List all got no response")
				return
			end

			all_songs = response
			search = all_songs

			-- format each row
			local sizes = util.split_length(
				width,
				config.config.window_search_format.sizes
			)
			local display_lines = {}

			-- start by printing all songs
			for i, entry in ipairs(all_songs) do
				local fmt = {}

				for j, header in ipairs(config.config.window_format.header) do
					fmt[j] = pad_string(
						tostring(entry[header] or ""),
						sizes[j],
						config.config.window_search_format.alignment[j]
					)
				end

				display_lines[i] = table.concat(fmt, " ")
			end

			vim.bo[buffer].modifiable = true
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, display_lines)
			vim.bo[buffer].modifiable = false


		end)
	end)

	-- update from search
	local function update()
		local input = vim.api.nvim_buf_get_lines(input_buffer, 0, 1, false)[1] or ""
		local lines = {}
	end

	vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
		buffer = input_buf,
		callback = update,
	})

	local input_window = vim.api.nvim_open_win(buffer, true)

	local result_window = vim.api.nvim_open_win(buffer, true, { -- take focus from queue
		relative = "editor",
		style = "minimal",
		border = "rounded",
		width = width,
		height = height,
		row = y,
		col = x,
		title = " Search ",
	})
	vim.wo[window].cursorline = true
	config.style_window(window)

	require("nmpc.keybind").setup_search_window(window, buffer)
end

choose = function (window, buffer)
	local idx = vim.api.nvim_win_get_cursor(window)[1]
    local line = vim.api.nvim_buf_get_lines(buffer, idx - 1, idx, false)[1]

	local id = queue[idx].id

	mpd.play(id, function (error)
		vim.schedule(function ()
			if not error then
				vim.notify("Now playing: " .. line)
			else
				vim.notify("Cant play: " .. line)
			end
		end)
	end)
end

return M
