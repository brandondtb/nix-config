-- Basic settings
vim.g.mapleader = " "

-- Colorscheme
vim.cmd("colorscheme tokyonight-night")

-- Configure netrw
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1
vim.g.netrw_winsize = 15

-- Line numbers
vim.wo.number = true

-- Mouse mode
vim.o.mouse = "a"

vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true

-- indent options
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2

vim.g.neoformat_enabled_lua = { "stylua" }
vim.g.neoformat_enabled_python = { "black" }
vim.g.neoformat_enable_javascript = { "prettier" }
vim.g.neoformat_enable_html = { "html-beautify" }
vim.g.neoformat_enable_htmldjango = { "djlint" }

-- Keymaps
vim.keymap.set("i", "fd", "<ESC>")

vim.keymap.set("n", "<Leader>n", ":Neotree toggle<CR>")

-- Diagnostic
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>sf", builtin.find_files, {})
vim.keymap.set("n", "<leader>sg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>sb", builtin.buffers, {})
vim.keymap.set("n", "<leader>sh", builtin.help_tags, {})
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })

-- Plugin configuration
local cmp = require("cmp")
local lspkind = require("lspkind")

cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
		end,
	},

	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},

	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),

	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol", -- show only symbol annotations
			maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
			ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
			symbol_map = { Copilot = "" },

			-- The function below will be called before any actual modifications from lspkind
			-- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
			before = function(entry, vim_item)
				return vim_item
			end,
		}),
	},

	sources = cmp.config.sources({
		{ name = "copilot" },
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "obsidian" },
		{ name = "obsidian_new" },
	}, {
		{ name = "buffer" },
	}),
})

-- Telescope
require("telescope").setup({
	defaults = {
		-- Default configuration for telescope goes here:
		-- config_key = value,
		mappings = {
			i = {
				-- map actions.which_key to <C-h> (default: <C-/>)
				-- actions.which_key shows the mappings for your picker,
				-- e.g. git_{create, delete, ...}_branch for the git_branches picker
				["<C-h>"] = "which_key",
			},
		},
	},
	pickers = {
		-- Default configuration for builtin pickers goes here:
		-- picker_name = {
		--   picker_config_key = value,
		--   ...
		-- }
		-- Now the picker_config_key will be applied every time you call this
		-- builtin picker
	},
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown(),
		},
		-- Your extension configuration goes here:
		-- extension_name = {
		--   extension_config_key = value,
		-- }
		-- please take a look at the readme of the extension you want to configure
	},
})

require("telescope").load_extension("ui-select")

-- Obsidian
require("obsidian").setup({
	legacy_commands = false,
	workspaces = {
		{
			name = "obsidian",
			path = "~/Sync/Obsidian",
		},
	},
	daily_notes = {
		folder = "daily",
		date_format = "%Y-%m-%d",
	},
	completion = {
		nvim_cmp = true,
	},
	note_id_func = function(title)
		if title ~= nil then
			return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
		end
		return tostring(os.time())
	end,
	picker = {
		name = "telescope.nvim",
	},
})

vim.keymap.set("n", "<leader>oo", "<cmd>Obsidian quick-switch<cr>", { desc = "Open/switch note" })
vim.keymap.set("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "New note" })
vim.keymap.set("n", "<leader>od", "<cmd>Obsidian today<cr>", { desc = "Today's daily note" })
vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", { desc = "Search notes" })
vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", { desc = "Show backlinks" })
vim.keymap.set("n", "<leader>ot", "<cmd>Obsidian tags<cr>", { desc = "Search tags" })

-- Tree-sitter: Grammars installed via Nix (withPlugins)
-- Highlighting enabled by default in Neovim 0.10+
-- Disable treesitter highlighting for large files
vim.api.nvim_create_autocmd("BufReadPre", {
	callback = function(args)
		local max_filesize = 100 * 1024 -- 100 KB
		local ok, stats = pcall(vim.loop.fs_stat, args.file)
		if ok and stats and stats.size > max_filesize then
			vim.treesitter.stop(args.buf)
		end
	end,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

-- Configure LSPs using new vim.lsp.config API (nvim 0.11+)
vim.lsp.config.pyright = {
	cmd = { 'pyright-langserver', '--stdio' },
	filetypes = { 'python' },
	root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
	capabilities = capabilities,
}

vim.lsp.enable('pyright')

-- Claude Code integration
require("claudecode").setup({
	auto_start = true,
	terminal = {
		split_side = "right",
		split_width_percentage = 0.30,
		provider = "snacks",
	},
	diff_opts = {
		auto_close_on_accept = true,
		vertical_split = true,
	},
})

-- Claude Code keymaps (per official docs)
vim.keymap.set("n", "<leader>a", "", { desc = "AI/Claude Code" })
vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add current buffer" })
vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send to Claude" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })

-- File tree integration (neo-tree, netrw, etc.)
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "neo-tree", "netrw" },
	callback = function()
		vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", { buffer = true, desc = "Add file" })
	end,
})
