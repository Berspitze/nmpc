local M = {}
local keybinds = require("nmpc.config").config.keybinds
local mpd = require("nmpc.mpd")

---establishes all keymaps
function M.setup()
	local ui = require("nmpc.ui")
	vim.api.nvim_create_user_command("Nmpc", function ()
		ui.queue_window()
	end, {})
end

function M.setup_queue_window(window, buffer)
	vim.keymap.set("n", keybinds.quit, function ()
		if vim.api.nvim_win_is_valid(window) then
			vim.api.nvim_win_close(window, true)
		end
	end)
	-- help = "?",
	-- toggle_pause = "z",
	-- toggle_repeat = "x",
	--
	-- -- chnge songs
	-- search = "/",
	-- search_add = "<C-a>",
	-- search_up = "<C-k>",
	-- search_down = "<C-j>",
	--
	-- -- music commands
	-- vim.keymap.set("n", keybinds.play, function ()
	--
	-- end)
	-- stop = "s",
	vim.keymap.set("n", keybinds.stop, function ()
		mpd.stop(function (error, response)
			vim.schedule(function ()
				if not error then 
					vim.notify("Stopped")
				else
					vim.notify("Cant stop song")
				end
			end)
		end)
	end)
	-- next = ">",
	-- prev = "<",
	-- volume_up = ".",
	-- volume_down = ",",
	-- seek_forward = "l", -- prepend by number
	-- seek_backward = "h", -- prepend by number
	-- up = "k",
	-- down = "j",
	-- shuffle = "S",
	-- random_fill = "X", -- prepend by number
end

return M
