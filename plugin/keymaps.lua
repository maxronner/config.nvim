local nmap = function(lhs, rhs, opts)
  vim.keymap.set("n", lhs, rhs, opts)
end
local xmap = function(lhs, rhs, opts)
  vim.keymap.set("x", lhs, rhs, opts)
end
local imap = function(lhs, rhs, opts)
  vim.keymap.set("i", lhs, rhs, opts)
end
local tmap = function(lhs, rhs, opts)
  vim.keymap.set("t", lhs, rhs, opts)
end

local nmap_leader = function(suffix, rhs, opts)
  vim.keymap.set("n", "<Leader>" .. suffix, rhs, opts)
end
local nxmap_leader = function(suffix, rhs, opts)
  vim.keymap.set({ "n", "x" }, "<Leader>" .. suffix, rhs, opts)
end

-- Cursor stays in place when joining lines / scrolling
nmap("J", "mzJ`z", { desc = "Join line below with cursor stay" })
nmap("<C-d>", "<C-d>zz", { desc = "Half page down, center screen" })
nmap("<C-u>", "<C-u>zz", { desc = "Half page up, center screen" })
nmap("n", "nzzzv", { desc = "Next match, center screen" })
nmap("N", "Nzzzv", { desc = "Prev match, center screen" })

-- Quickfix / location list navigation
nmap("<C-j>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
nmap("<C-k>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
nmap_leader("j", "<cmd>lnext<CR>zz", { desc = "Next loclist" })
nmap_leader("k", "<cmd>lprev<CR>zz", { desc = "Prev loclist" })
nmap_leader("e", "<C-6>", { desc = "Alternate buffer" })
nmap_leader("qq", function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, { desc = "Toggle quickfix window" })

xmap("/", "<C-\\><C-n>`</\\%V", { desc = "Search forward within visual selection" })
xmap("?", "<C-\\><C-n>`>?\\%V", { desc = "Search backward within visual selection" })

---- Editing ----
imap("<C-d>", "<Del>", { desc = "Delete char (insert mode)" })
nmap("<leader>|", "gMea<CR><Esc>", { desc = "Split line at midpoint" })
nmap_leader("lf", vim.lsp.buf.format, { desc = "LSP: Format buffer" })
nmap("<leader>qd", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })
nmap("<C-Del>", "dw", { desc = "Delete word (normal mode)" })
imap("<C-Del>", "<C-o>dw", { desc = "Delete word (insert mode)" })
nxmap_leader("d", '"_d', { desc = "Delete (black hole register)" })

---- Search ----
nmap("<C-s>", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor" })
nmap("<C-t>", [[:%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute text under cursor" })
xmap("<C-t>", [[:%s/<C-r>"/<C-r>"/gI<Left><Left><Left>]], { desc = "Substitute visual selection" })
nmap("<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

---- Files ----
nmap_leader("xf", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })
nmap_leader("xF", "<cmd>!chmod -x %<CR>", { silent = true, desc = "Remove exec permission" })
nmap_leader("<leader>", "<cmd>so<CR>", { desc = "Source current file" })

---- Clipboard ----
nxmap_leader("D", [["+d]], { desc = "Cut to system clipboard" })
nxmap_leader("y", [["+y]], { desc = "Yank to system clipboard" })
nmap_leader("Y", [["+Y]], { desc = "Yank line to system clipboard" })

---- Logic ----
nmap_leader("cf", "<cmd>!find . -type f -not -path '*/.git/*' | wc -l<CR>", { desc = "Count files in directory" })
nmap_leader(
  "cd",
  "<cmd>!find . -type f -not -path '*/.git/*' -exec wc -l {} \\; | awk '{ total += $1 } END { print \"Lines in workspace: \" total }'<CR>",
  { desc = "Count lines in all files of current directory" }
)

-- Terminal mode
tmap("<Esc>", "<C-\\><C-n>", { desc = "Escape terminal mode" })
