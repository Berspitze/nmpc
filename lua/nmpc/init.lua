local M = {}

local config = require("nmpc.config")
local commands = require("nmpc.commands")

function M.configure(opts)
	config.setup(opts)
	commands.setup()
end

print(config.config.greeting)

return M
