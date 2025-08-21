-- backup, undo and swap
vim.opt.backup = true
vim.opt.undofile = true
vim.opt.swapfile = true

-- make sure '.' is tried last
vim.opt.backupdir:remove({ '.' })
vim.opt.backupdir:append({ '.' })

-- various settings I like
vim.opt.clipboard:prepend({ 'unnamed' })
vim.opt.complete:append({ 'i', 'd' })
vim.opt.completeopt:append({ 'menuone', 'noinsert', 'noselect' })
vim.opt.foldlevelstart = 99
vim.opt.foldmethod = 'indent'
vim.opt.number = true
vim.opt.path = '.,,**'
vim.opt.shiftround = true
vim.opt.virtualedit = 'block'
vim.cmd [[
	set wildcharm=<C-Z>
]]

vim.opt.tabstop = 4
vim.opt.shiftwidth = 0
vim.o.softtabstop = vim.o.tabstop

-- nicer grepping
if vim.fn.executable('rg') then
	vim.opt.grepprg = 'rg --vimgrep --no-heading'
	vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end


-- autocommands
local vimrc_group = vim.api.nvim_create_augroup('vimrc', { clear = true })
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  pattern = '[^l]*',
  group = vimrc_group,
  command = 'cwindow',
})
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  pattern = 'l*',
  group = vimrc_group,
  command = 'lwindow',
})
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  group = vimrc_group,
  callback = function()
	  vim.keymap.set('n', '{', '?^@@<CR>', { buffer = true })
	  vim.keymap.set('n', '}', '/^@@<CR>', { buffer = true })
	  vim.opt_local.iskeyword:append({ '-' })
  end,
})
vim.api.nvim_create_autocmd('CompleteDone', {
  pattern = '*',
  group = vimrc_group,
  command = 'silent! pclose',
})

-- only highlight matches while searching
vim.api.nvim_create_autocmd('CmdlineEnter', {
  pattern = '/,?',
  group = vimrc_group,
  callback = function()
	  vim.opt.hlsearch = true
  end
})
vim.api.nvim_create_autocmd('CmdlineLeave', {
  pattern = '/,?',
  group = vimrc_group,
  callback = function()
	  vim.opt.hlsearch = false
  end
})


-- fix nvim's horrible descision
vim.keymap.set('n', 'Y', 'yy', { remap = true })

-- files
vim.keymap.set('n', '<leader>f', ':find *', { remap = true })

-- buffers
vim.keymap.set('n', '<leader>b', ':buffer *', { remap = true })
vim.keymap.set('n', '<leader>a', ':buffer#<CR>', { remap = true })

-- command-line
vim.keymap.set('c', '<C-k>', '<Up>', { remap = true })
vim.keymap.set('c', '<C-j>', '<Down>', { remap = true })

-- location/quickfix entries
vim.keymap.set('n','[q', ':cprevious<CR>', { remap = true })
vim.keymap.set('n',']q', ':cnext<CR>', { remap = true })
vim.keymap.set('n','[l', ':lprevious<CR>', { remap = true })
vim.keymap.set('n',']l', ':lnext<CR>', { remap = true })

-- search and replace
vim.keymap.set('n', '<Space><Space>', [[:'{,'}s/\<<C-r>=expand("<cword>")<CR>\>//g<left><left>]], { remap = true })
vim.keymap.set('n', '<Space>%', [[:%s/\<<C-r>=expand("<cword>")<CR>\>//g<left><left>]], { remap = true })

-- global commands
vim.keymap.set('n', '<Leader>g', ':g//#<Left><Left>', { remap = true })

-- windows
vim.keymap.set('n', '<C-w>z', ':wincmd z<Bar>cclose<Bar>lclose<CR>', { remap = true, silent = true })

-- background
vim.keymap.set('n', '[b', ':<C-U>set background=<C-R>=&background == "dark" ? "light" : "dark"<CR><CR>', { remap = true })

-- grepping
-- TODO: port this to lua
vim.cmd [[
	function! Grep(...)
		return system(join([&grepprg] + [expandcmd(join(a:000, ' '))], ' '))
	endfunction

	command! -nargs=+ -complete=file_in_path -bar Grep  cgetexpr Grep(<f-args>)
	command! -nargs=+ -complete=file_in_path -bar LGrep lgetexpr Grep(<f-args>)

	cnoreabbrev <expr> grep  (getcmdtype() ==# ':' && getcmdline() ==# 'grep')  ? 'Grep'  : 'grep'
	cnoreabbrev <expr> lgrep (getcmdtype() ==# ':' && getcmdline() ==# 'lgrep') ? 'LGrep' : 'lgrep'

	augroup quickfix
		autocmd!
		autocmd QuickFixCmdPost cgetexpr cwindow
		autocmd QuickFixCmdPost lgetexpr lwindow
	augroup END
]]

-- searching
vim.keymap.set('c', '<Tab>', function()
	if vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?" then return '<CR>/<c-r>/' end
	return '<c-z>'
end, { expr = true, remap = true })
vim.keymap.set('c', '<S-Tab>', function()
	if vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?" then return '<CR>?<c-r>/' end
	return '<S-Tab>'
end, { expr = true, remap = true})

-- scratch buffer
vim.api.nvim_create_user_command('SC',
	function(opts)
		vim.cmd ':vnew'	
		vim.opt_local.buflisted = false
		vim.opt_local.buftype = 'nofile'
		vim.opt_local.bufhidden = 'wipe'
		vim.opt_local.swapfile = false
	end,
	{
		desc = 'Open a scratch buffer',
		force = true,
		nargs = 0
	}
)

-- sudo write
if vim.fn.executable('sudo') then
	vim.api.nvim_create_user_command('W', 'silent! write !sudo tee % >/dev/null', {
		force = true,
	})
end

-- portable git blame
vim.api.nvim_create_user_command('GB',
	function(opts)
		path = vim.fn.shellescape(vim.fn.expand('%:p:h'))
		file = vim.fn.expand('%:t')
		cmd = 'git -C ' .. path .. ' blame -L ' .. opts.line1 .. ',' .. opts.line2 .. ' ' .. file
		syslist = vim.fn.systemlist(cmd)
		result = vim.fn.join(syslist, '\n')
		vim.api.nvim_echo({ { result }, { '' } }, false, {} )
	end,
	{
		desc = 'Portable git blame',
		force = true,
		range = true,
		nargs = 0
	}
)

-- crate directories
vim.keymap.set('n', '<leader>m', ':!mkdir -p %:h<CR>', { remap = true })


-- plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

-- then, setup!
require("lazy").setup({
	-- treesitter
	{"nvim-treesitter/nvim-treesitter", branch = 'master', lazy = false, build = ":TSUpdate"},
	-- colorscheme
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd("colorscheme rose-pine")
		end
	},
	-- LSP
	{
		'neovim/nvim-lspconfig',
		config = function()
			-- Setup language servers.

			-- Rust
			vim.lsp.config('rust_analyzer', {
				-- Server-specific settings. See `:help lspconfig-setup`
				settings = {
					["rust-analyzer"] = {
						cargo = {
							features = "all",
						},
						checkOnSave = {
							enable = true,
						},
						check = {
							command = "clippy",
						},
						imports = {
							group = {
								enable = false,
							},
						},
						completion = {
							postfix = {
								enable = false,
							},
						},
					},
				},
			})
			vim.lsp.enable('rust_analyzer')

			-- Bash LSP
			if vim.fn.executable('bash-language-server') == 1 then
				vim.lsp.enable('bashls')
			end

			-- texlab for LaTeX
			if vim.fn.executable('texlab') == 1 then
				vim.lsp.enable('texlab')
			end

			-- Ruff for Python
			if vim.fn.executable('ruff') == 1 then
				vim.lsp.enable('ruff')
			end

			-- nil for Nix
			if vim.fn.executable('nil') == 1 then
				vim.lsp.enable('nil_ls')
			end

			-- Global mappings.
			-- See `:help vim.diagnostic.*` for documentation on any of the below functions
			vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
			vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
			vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
			vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

			-- Use LspAttach autocommand to only map the following keys
			-- after the language server attaches to the current buffer
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('UserLspConfig', {}),
				callback = function(ev)
					-- Enable completion triggered by <c-x><c-o>
					vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					local opts = { buffer = ev.buf }
					vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
					vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
					vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
					vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
					vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
					vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
					vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
					vim.keymap.set('n', '<leader>wl', function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, opts)
					--vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
					vim.keymap.set('n', '<leader>R', vim.lsp.buf.rename, opts)
					vim.keymap.set({ 'n', 'v' }, '<leader>A', vim.lsp.buf.code_action, opts)
					vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
					vim.keymap.set('n', '<leader>=', function()
						vim.lsp.buf.format { async = true }
					end, opts)

					local client = vim.lsp.get_client_by_id(ev.data.client_id)

					-- TODO: find some way to make this only apply to the current line.
					if client.server_capabilities.inlayHintProvider then
						vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
					end

					-- None of this semantics tokens business.
					-- https://www.reddit.com/r/neovim/comments/143efmd/is_it_possible_to_disable_treesitter_completely/
					client.server_capabilities.semanticTokensProvider = nil
				end,
			})
		end
	},
	{ 'ggml-org/llama.vim' },
	{ 'godlygeek/tabular'},
	{ 'tpope/vim-surround' },
})
