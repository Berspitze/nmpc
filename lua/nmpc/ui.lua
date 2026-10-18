local M = {}
local config = require("nmpc.config")

-- forward declare
local load_playlist

function M.open()
	local width = math.floor(vim.o.columns * 0.6)
	local out_height = math.floor(vim.o.lines * 0.5)
	local in_height = 1 -- input field
	local total_height = (out_height + 2) + (in_height + 2) -- borders added
	local row0    = math.floor((vim.o.lines - total_height) / 2)
	local col0    = math.floor((vim.o.columns - width) / 2)

	-- buffers for content
	local out_buffer = vim.api.nvim_create_buf(false, true)
	local in_buffer = vim.api.nvim_create_buf(false, true)
	vim.bo[in_buffer].buftype    = "prompt" -- makes it editable
	vim.bo[in_buffer].bufhidden  = "wipe"
	vim.bo[out_buffer].bufhidden = "wipe"

	-- windows: top not focused, bot focused(for input)
	local out_window = vim.api.nvim_open_win(out_buffer, false, {
		relative = "editor",
		style = "minimal",
		border = { "╭", "─", "╮", "│", "┤", "─", "├", "│" },
		width = width,
		height = out_height,
		row = row0,
		col = col0,
		title = " Out ",
		zindex = 50,
	})
	local in_window = vim.api.nvim_open_win(in_buffer, true, {
		relative = "editor",
		style = "minimal",
		border = { "├", "─", "┤", "│", "╯", "─", "╰", "│" },
		width = width,
		height = 1,
		row = row0 + out_height,
		col = col0,
		zindex = 51,
	})

	-- colors
	config.style_window(in_window)
	config.style_window(out_window)

	-- making editable
	local prompt = " > "
	vim.fn.prompt_setprompt(in_buffer, prompt)

	-- update ui
	load_playlist(out_buffer)

	local function close()
		vim.cmd("stopinsert")
		for _, w in ipairs({ in_window, out_window }) do
			if vim.api.nvim_win_is_valid(w) then
				vim.api.nvim_win_close(w, true)
			end
		end
	end

	local opt = { buffer = in_buffer, noremap = true, silent = true }
	vim.keymap.set({ "i", "n" }, config.config.keybinds.quit, close, opt)

	vim.cmd("startinsert")
end

-- mpc commands+
load_playlist = function (buf)
	vim.system({ "mpc", "playlist" }, { text = true }, function (res)
		vim.schedule(function ()
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			
			-- try loading lines into buf
			local lines
			if res.code ~= 0 then
				lines = { "mpc failed: " .. (res.stderr or "") }
			else
				lines = vim.split(
					res.stdout,
					"\n",
					{ trimempty = true }
				)
			end

			-- update everything
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		end)

	end)
end

return M
