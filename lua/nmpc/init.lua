local M = {}

function M.setup(opts)
	require("nmpc.config").setup(opts)
	require("nmpc.keybind").setup()
end

return M
