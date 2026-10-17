local config = require("nmpc.config")
local M = {}

local function setup_hl()
	local t = config.config.theme
	local set = function(name, value)
		vim.api.nvim_set_hl(0, name, value)
	end

	set("NmpcNormal",  { fg = t.foreground, bg = t.background })
	set("NmpcBorder",  { fg = t.border,     bg = t.background })
	set("NmpcTitle",   { fg = t.title,      bg = t.background, bold = true })
	set("NmpcSelect",  { bg = t.selection })
	set("NmpcPrompt",  { fg = t.prompt,     bg = t.background })
end

local WINHL = table.concat({
	"Normal:NmpcNormal",
	"NormalFloat:NmpcNormal",
	"FloatBorder:NmpcBorder",
	"FloatTitle:NmpcTitle",
	"CursorLine:NmpcSelect",
}, ",")

function M.open()
	-- preloading
	setup_hl()

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
	vim.wo[out_window].winhighlight = WINHL
	vim.wo[in_window].winhighlight = WINHL
	vim.wo[out_window].cursorline = true

	-- making editable
	local prompt = "> "
	vim.fn.prompt_setprompt(in_buffer, prompt)

	local function close()
		vim.cmd("stopinsert")
		for _, w in ipairs({ in_window, out_window }) do
			if vim.api.nvim_win_is_valid(w) then
				vim.api.nvim_win_close(w, true)
			end
		end
	end

	local opt = { buffer = in_buffer, nowait = true }
	vim.keymap.set({ "i", "n" }, "<Esc>", close, opt)
	vim.keymap.set("i", "<C-c>", close, opt)

	vim.cmd("startinsert")
end

return M
