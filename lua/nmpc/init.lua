local M = {}

function M.setup(opts)
	require("nmpc.config").setup(opts)
	require("nmpc.commands").setup()
end

return M
