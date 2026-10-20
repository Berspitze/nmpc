local M = {}

M.config = {
	general = {
		volume_step = 1, -- 0-100 vol, inc/dec by n
	},

	window_format = { -- only supports: 'title', 'artist', 'time' as input
		header = { "title", "artist", "time" },
		sizes = { "50%", "40%", 5 }, -- percentage based
		alignment = { "left", "left", "right"},
		color = { "#ff0000", "#00ff00", "#0000ff" }
	},

	mpd = { -- specified in mpd.conf
		bind_to_address = "127.0.0.1",
		port = 6600,
	},

	keybinds = {
		quit = "<Esc>",
		help = "?",
		toggle_pause = "z",
		toggle_repeat = "x",

		-- chnge songs
		search = "/",
		search_add = "<C-a>",
		search_up = "<C-k>",
		search_down = "<C-j>",

		-- music commands
		play = "p",
		stop = "s",
		next = ">",
		prev = "<",
		volume_up = ".",
		volume_down = ",",
		seek_forward = "l", -- prepend by number
		seek_backward = "h", -- prepend by number
		up = "k",
		down = "j",
		shuffle = "S",
		random_fill = "X", -- prepend by number
	},

	theme = {
		background = "None",
		foreground = "#E2E2E3",
		border     = "#44475A",
		title      = "#9ED072",
		selection  = "#3E445E",
		prompt     = "#9ED072",
	},
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend(
        "force",
        M.config,
        opts or {}
    )

	-- check for validity of config

	-- coloring window
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

	for i, _ in ipairs(M.config.window_format.header) do
		vim.api.nvim_set_hl(0, "NmpcHeader" .. i, {
			fg = M.config.window_format.color[i]
		})
	end
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
