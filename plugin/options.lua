-- Editing
vim.opt.isfname:append("@-@") -- Allow @ in file names
vim.opt.timeout        = true
vim.opt.timeoutlen     = 300
vim.opt.confirm        = true
vim.opt.updatetime     = 50
vim.opt.splitright     = true
vim.opt.splitbelow     = true
vim.opt.spelloptions   = 'camel'               -- Treat camelCase word parts as separate words
vim.opt.virtualedit    = "block"               -- Allow going past end of line in blockwise mode
vim.opt.iskeyword      = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part

-- UI
vim.opt.breakindent    = true -- Indent wrapped lines to match line start
vim.opt.scrolloff      = 8
vim.opt.signcolumn     = "yes"
vim.opt.colorcolumn    = "80"
vim.opt.relativenumber = true
vim.opt.nu             = true

-- Indentation
vim.opt.tabstop        = 4     -- Show tab as this number of spaces
vim.opt.softtabstop    = 4
vim.opt.shiftwidth     = 4     -- Use this number of spaces for indentation
vim.opt.autoindent     = true
vim.opt.expandtab      = true  -- Convert tabs to spaces
vim.opt.smartindent    = true
vim.opt.wrap           = false -- Visually wrap lines (toggle with \w)

-- Files
vim.opt.undofile       = true

-- Search
vim.opt.hlsearch       = true
vim.opt.incsearch      = true
vim.opt.ignorecase     = true -- Ignore case during search
vim.opt.smartcase      = true -- Respect case if search pattern has upper case
vim.opt.path           = ".,**"

-- Terminal
vim.opt.termguicolors  = true

-- Tree-sitter based folding for all filetypes
vim.opt.foldmethod     = "expr"
vim.opt.foldexpr       = "nvim_treesitter#foldexpr()"
vim.opt.foldenable     = true
vim.opt.foldlevel      = 99
vim.opt.foldlevelstart = 99

-- Grep
vim.opt.grepprg        = "rg --vimgrep"
vim.opt.grepformat     = "%f:%l:%c:%m"
