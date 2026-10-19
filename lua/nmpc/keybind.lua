local M = {}
local general = require("nmpc.config").config.general
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
		mpd.stop(function (error)
			vim.schedule(function ()
				if not error then
					vim.notify("Stopped")
				else
					vim.notify(error)
				end
			end)
		end)
	end)
	-- next = ">",
	-- prev = "<",
	vim.keymap.set("n", keybinds.volume_up, function ()
		mpd.change_volume(general.volume_step, function (error, response)
			vim.schedule(function ()
				if error then
					vim.notify(error)
				end
				if response then
					vim.notify("Volume: " .. response)
				end
			end)
		end)
	end)
	vim.keymap.set("n", keybinds.volume_down, function ()
		mpd.change_volume(-general.volume_step, function (error, response)
			vim.schedule(function ()
				if error then
					vim.notify(error)
				end
				if response then
					vim.notify("Volume: " .. response)
				end
			end)
		end)
	end)
	-- seek_forward = "l", -- prepend by number
	-- seek_backward = "h", -- prepend by number
	-- up = "k",
	-- down = "j",
	-- shuffle = "S",
	-- random_fill = "X", -- prepend by number
end

return M
