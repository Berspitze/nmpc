local M = {}
local config = require("nmpc.config")

---establishes all keymaps
function M.setup()
	local ui = require("nmpc.ui")
	vim.api.nvim_create_user_command("Nmpc", function ()
		ui.open()
	end, {})

    vim.keymap.set("n", "<leader>nm", function()
        ui.open()
    end, {
        desc = "Open NMPC window",
    })

	-- popup specific keymaps
	vim.keymap.set("n", config.config.keybinds., function ()

	end, options)

end

return M
