local M = {}

M.config = {
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

	M.setup_hl()

	local group = vim.api.nvim_create_augroup(
        "NmpcHighlights",
        { clear = true }
    )

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = M.setup_hl,
    })
end

-- color configuration
function M.setup_hl()
	local t = M.config.theme

	vim.api.nvim_set_hl(0, "NmpcNormal",  { fg = t.foreground, bg = t.background })
	vim.api.nvim_set_hl(0, "NmpcBorder",  { fg = t.border,     bg = t.background })
	vim.api.nvim_set_hl(0, "NmpcTitle",   { fg = t.title,      bg = t.background, bold = true })
	vim.api.nvim_set_hl(0, "NmpcSelect",  { bg = t.selection })
	vim.api.nvim_set_hl(0, "NmpcPrompt",  { fg = t.prompt,     bg = t.background })
end

function M.style_window(win)
	vim.wo[win].winhighlight = table.concat({
		"Normal:NmpcNormal",
		"NormalFloat:NmpcNormal",
		"FloatBorder:NmpcBorder",
		"FloatTitle:NmpcTitle",
		"CursorLine:NmpcSelect",
	}, ",")
end

return M
