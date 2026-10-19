local M = {}
-- local config = require("nmpc.config")

---establishes all keymaps
function M.setup()
	local ui = require("nmpc.ui")
	vim.api.nvim_create_user_command("Nmpc", function ()
		ui.queue_window()
	end, {})





	-- popup specific keymaps
	-- local options = {
	-- 	buffer = buf
	-- }
	--
	-- vim.keymap.set("n", config.config.keybinds., function ()
	--
	-- end, options)
end

return M
