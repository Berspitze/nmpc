local M = {}

M.config = {
    greeting = "Hello from nmpc!",
	theme = {
		background = "None",
		foreground = "#E2E2E3",
		border     = "#44475A",
		title      = "#9ED072",
		selection  = "#3E445E",
		prompt     = "#9ED072",
	}
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend(
        "force",
        M.config,
        opts or {}
    )
end

return M
