local M = {}
local config = require("nmpc.config")

-- forward declare
-- local search_window
local queue_list

function M.queue_window()
	local width  = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.5)
	local x      = math.floor((vim.o.columns - width) / 2)
	local y      = math.floor((vim.o.lines - height) / 2)

	-- buffers for content
	local buffer = vim.api.nvim_create_buf(false, true)

	-- fill buffer with queue content
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, queue_list())

	vim.bo[buffer].modifiable = false
	vim.bo[buffer].bufhidden = "wipe"



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


	local function close()
		if vim.api.nvim_win_is_valid(window) then
			vim.api.nvim_win_close(window, true)
		end
	end

	local function choose()
		local idx = vim.api.nvim_win_get_cursor(window)[1]
		close()
		vim.notify("You picked " .. queue_list()[idx])
	end

	local function map(lhs, fn)
		vim.keymap.set("n", lhs, fn, { buffer = buffer, nowait = true })
	end

	map("<CR>", choose)
	map("q", close)
	map("<Esc>", close)
end

-- local function search_window()
-- 	local width = math.floor(vim.o.columns * 0.6)
-- 	local height = math.floor(vim.o.lines * 0.5)
--
--
-- end
--


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

-- mpc commands+
queue_list = function ()
	-- try loading lines into buf
	local res = vim.system({ "mpc", "playlist" }, { text = true }):wait()
	if res.code ~= 0 then
		return { "mpc failed: " .. (res.stderr or "") }
	end

	return vim.split(res.stdout, "\n", { trimempty = true })
end

return M
