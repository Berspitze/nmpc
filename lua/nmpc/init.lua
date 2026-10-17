local M = {}

local config = require("nmpc.config")
local commands = require("nmpc.commands")

function M.setup(opts)
	config.setup(opts)
	commands.setup()
end

return M
