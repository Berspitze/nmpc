local M = {}

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
end

return M
