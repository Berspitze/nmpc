local M = {}

local state = {}

local function reset_state()
	state = {
		queue = { buf = nil, win = nil, cursor = nil },
		search = { input_buf = nil, result_buf = nil, input_win = nil, result_win = nil },
	}
end
reset_state()

local function valid_buf(b) return b and vim.api.nvim_buf_is_valid(b) end
local function valid_win(w) return w and vim.api.nvim_win_is_valid(w) end

local function geometry(height)
	local width = 60
	return {
		width = width,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
	}
end

-- ---------- search ----------

local function close_search_windows()
	local s = state.search
	for _, w in ipairs({ s.input_win, s.result_win }) do
		if valid_win(w) then vim.api.nvim_win_close(w, true) end
	end
	s.input_win, s.result_win = nil, nil
	vim.cmd("stopinsert")
end

local function update_search()
	local s = state.search
	if not valid_buf(s.input_buf) then return end
	local text = vim.api.nvim_buf_get_lines(s.input_buf, 0, 1, false)[1] or ""
	local results = {} -- filter your data using `text`
	vim.bo[s.result_buf].modifiable = true
	vim.api.nvim_buf_set_lines(s.result_buf, 0, -1, false, results)
	vim.bo[s.result_buf].modifiable = false
end

local function close_search()
	close_search_windows()
	if valid_win(state.queue.win) then
		vim.api.nvim_set_current_win(state.queue.win)
	end
end

local function open_search()
	if valid_win(state.search.input_win) then return end
	local s = state.search

	if not (valid_buf(s.input_buf) and valid_buf(s.result_buf)) then
		s.input_buf = vim.api.nvim_create_buf(false, true)
		s.result_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[s.result_buf].modifiable = false

		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			buffer = s.input_buf,
			callback = update_search,
		})

		vim.keymap.set({ "i", "n" }, "<Esc>", close_search, { buffer = s.input_buf })
		vim.keymap.set({ "i", "n" }, "<CR>", function()
			-- act on the selection here
			close_search()
		end, { buffer = s.input_buf })
	end

	local g = geometry(19)
	s.input_win = vim.api.nvim_open_win(s.input_buf, true, {
		relative = "editor", row = g.row, col = g.col,
		width = g.width, height = 1,
		style = "minimal", border = "rounded", title = " Search ",
		zindex = 60,
	})
	s.result_win = vim.api.nvim_open_win(s.result_buf, false, {
		relative = "editor", row = g.row + 3, col = g.col,
		width = g.width, height = 15,
		style = "minimal", border = "rounded", focusable = false,
		zindex = 60,
	})

	local line = vim.api.nvim_buf_get_lines(s.input_buf, 0, 1, false)[1] or ""
	vim.api.nvim_win_set_cursor(s.input_win, { 1, #line })
	vim.cmd("startinsert!")
end

-- ---------- queue ----------

-- closes everything and frees all buffers and state
function M.close()
	close_search_windows()
	if valid_win(state.queue.win) then vim.api.nvim_win_close(state.queue.win, true) end
	for _, b in ipairs({ state.queue.buf, state.search.input_buf, state.search.result_buf }) do
		if valid_buf(b) then vim.api.nvim_buf_delete(b, { force = true }) end
	end
	reset_state()
end

function M.refresh_queue(queue)
	local buf = state.queue.buf
	if not valid_buf(buf) then return end
	local lines = {}
	for i, e in ipairs(queue) do lines[i] = e.name end
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	-- reapply extmark highlights here
end

function M.open()
	-- already open: just focus it
	if valid_win(state.queue.win) then
		vim.api.nvim_set_current_win(state.queue.win)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	state.queue.buf = buf

	vim.keymap.set("n", "/", open_search, { buffer = buf })
	vim.keymap.set("n", "<Esc>", M.close, { buffer = buf })
	vim.keymap.set("n", "q", M.close, { buffer = buf })

	local g = geometry(15)
	state.queue.win = vim.api.nvim_open_win(buf, true, {
		relative = "editor", row = g.row, col = g.col,
		width = g.width, height = 15,
		style = "minimal", border = "rounded", title = " Queue ",
	})

	-- if the user closes the window some other way (:q, :close), free everything
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(function()
				if state.queue.buf == buf then M.close() end
			end)
		end,
	})

	M.refresh_queue(get_queue()) -- your function that fetches the queue
end

vim.api.nvim_create_user_command("Nmpc", M.open, {})

return M
