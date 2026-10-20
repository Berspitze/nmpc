local M = {}
local config = require("nmpc.config")
local mpd = require("nmpc.mpd")
local pad_string = require("nmpc.util").pad_string

-- stores all songs
local queue = {}

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

local function search_window()
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.5)
end



-- function M.open()
-- 	local width = math.floor(vim.o.columns * 0.6)
-- 	local out_height = math.floor(vim.o.lines * 0.5)
-- 	local in_height = 1 -- input field
-- 	local total_height = (out_height + 2) + (in_height + 2) -- borders added
-- 	local row0    = math.floor((vim.o.lines - total_height) / 2)
-- 	local col0    = math.floor((vim.o.columns - width) / 2)
--
-- 	-- buffers for content
-- 	local out_buffer = vim.api.nvim_create_buf(false, true)
-- 	local in_buffer = vim.api.nvim_create_buf(false, true)
-- 	vim.bo[in_buffer].buftype    = "prompt" -- makes it editable
-- 	vim.bo[in_buffer].bufhidden  = "wipe"
-- 	vim.bo[out_buffer].bufhidden = "wipe"
--
-- 	-- windows: top not focused, bot focused(for input)
-- 	local out_window = vim.api.nvim_open_win(out_buffer, false, {
-- 		relative = "editor",
-- 		style = "minimal",
-- 		border = { "╭", "─", "╮", "│", "┤", "─", "├", "│" },
-- 		width = width,
-- 		height = out_height,
-- 		row = row0,
-- 		col = col0,
-- 		title = " Out ",
-- 		zindex = 50,
-- 	})
-- 	local in_window = vim.api.nvim_open_win(in_buffer, true, {
-- 		relative = "editor",
-- 		style = "minimal",
-- 		border = { "├", "─", "┤", "│", "╯", "─", "╰", "│" },
-- 		width = width,
-- 		height = 1,
-- 		row = row0 + out_height,
-- 		col = col0,
-- 		zindex = 51,
-- 	})
--
-- 	-- colors
-- 	config.style_window(in_window)
-- 	config.style_window(out_window)
--
-- 	-- making editable
-- 	local prompt = " > "
-- 	vim.fn.prompt_setprompt(in_buffer, prompt)
--
-- 	-- update ui
-- 	load_playlist(out_buffer)
--
-- 	local function close()
-- 		vim.cmd("stopinsert")
-- 		for _, w in ipairs({ in_window, out_window }) do
-- 			if vim.api.nvim_win_is_valid(w) then
-- 				vim.api.nvim_win_close(w, true)
-- 			end
-- 		end
-- 	end
--
-- 	local opt = { buffer = in_buffer, noremap = true, silent = true }
-- 	vim.keymap.set({ "i", "n" }, config.config.keybinds.quit, close, opt)
--
-- 	vim.cmd("startinsert")
-- end
--
-- -- draw queue
--
-- -- draw search

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
