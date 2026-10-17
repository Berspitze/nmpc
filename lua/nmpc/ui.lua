local M = {}

function M.open()
	local buf = vim.api.nvim_create_buf(false, true)
	local w, h = math.floor(vim.o.columns * 0.6), math.floor(vim.o.lines * 0.5)

	-- creates window in the center
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor", width = w, height = h,
		col = math.floor((vim.o.columns - w) / 2),
		row = math.floor((vim.o.lines - h) / 2),
		style = "minimal", border = "rounded",
	})
	vim.bo[buf].buftype = "prompt"
	vim.fn.prompt_setprompt(buf, "> ")
	vim.fn.prompt_setcallback(buf, function(text)
		vim.api.nvim_win_close(win, true)
		print("selected: " .. text)
	end)
	vim.cmd("startinsert")
end

return M
