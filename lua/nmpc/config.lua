local M = {}

M.config = {
    greeting = "Hello from nmpc!",
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend(
        "force",
        M.config,
        opts or {}
    )
end

return M
