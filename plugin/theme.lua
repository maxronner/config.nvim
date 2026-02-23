-- Terminal cterm palette slots 0-15.
-- The terminal (ghostty) maps these to theme-specific hex values,
-- so highlight groups stay correct across any theme thememanager loads.
--
-- Conventional ANSI slot roles:
--   C0  black / background shade
--   C1  red
--   C2  green  (some themes put blue/teal here, e.g. rose-pine)
--   C3  yellow
--   C4  blue   (some themes put cyan/teal here, e.g. rose-pine)
--   C5  magenta / purple
--   C6  cyan   (some themes put rose/pink here, e.g. rose-pine)
--   C7  white / foreground
--   C8  bright black / muted / overlay
--   C9  bright red
--   C10 bright green
--   C11 bright yellow
--   C12 bright blue / cyan
--   C13 bright magenta / purple
--   C14 bright cyan / rose
--   C15 bright white

local C0 = 0
local C1 = 1
local C2 = 2
local C3 = 3
local C4 = 4
local C5 = 5
local C6 = 6
local C7 = 7
local C8 = 8
local C9 = 9
local C10 = 10
local C11 = 11
local C12 = 12
local C13 = 13
local C14 = 14
local C15 = 15

-- Remap foreground-role slots that are too dark to contrast against the bg.
-- Some wallpaper-derived palettes put very dark colors in slots that the
-- theme uses for visible syntax (C5/C6/C9/C12). When a slot's perceived
-- luminance is close to the background, substitute its "bright" counterpart.
do
  local palette_path = vim.fn.expand("$XDG_CONFIG_HOME/thememanager/palette.json")
  local f = io.open(palette_path, "r")
  if f then
    local content = f:read("*a")
    f:close()

    --- @param hex string  6-char hex string
    --- @return number perceived luminance 0–255
    local function lum(hex)
      local r = tonumber(hex:sub(1, 2), 16) or 0
      local g = tonumber(hex:sub(3, 4), 16) or 0
      local b = tonumber(hex:sub(5, 6), 16) or 0
      return 0.299 * r + 0.587 * g + 0.114 * b
    end

    local bg_hex = content:match('"bg"%s*:%s*"#?([0-9a-fA-F]+)"') or "000000"
    local bg_lum = lum(bg_hex)

    --- Return the slot index to use: `slot` if contrast is sufficient, else `fallback`.
    --- @param slot integer  terminal palette index (0–15)
    --- @param fallback integer  replacement slot
    --- @return integer
    local function fg_slot(slot, fallback)
      local hex = content:match('"color' .. slot .. '"%s*:%s*"#?([0-9a-fA-F]+)"')
      if not hex or #hex < 6 then
        return slot
      end
      local contrast = math.abs(lum(hex) - bg_lum)
      return contrast < 60 and fallback or slot
    end

    -- Guard slots used for prominent foreground syntax colors.
    -- Fallbacks are the "bright" counterpart in the conventional ANSI layout.
    C5 = fg_slot(5, 13) -- Statement/Keyword  → bright magenta
    C6 = fg_slot(6, 14) -- Special/Info       → bright cyan/rose
    C9 = fg_slot(9, 1) -- Boolean/Exception  → normal red (already bright)
    C12 = fg_slot(12, 4) -- Function/Include   → normal blue/teal
  end
end

--- @param r integer 0-5 inclusive
--- @param g integer 0-5 inclusive
--- @param b integer 0-5 inclusive
local function rgb(r, g, b)
  return 16 + r * 36 + g * 6 + b
end

--- @param shade integer 0-23 inclusive
local function grey(shade)
  local is_light = vim.g.theme_background == "light"
  -- On a light theme invert the grey scale so low shades are near-white
  -- and high shades are near-black, preserving contrast in both modes.
  local idx = is_light and (23 - shade) or shade
  return 232 + idx
end

---@class (exact) HighlightOpts
---@field fg? integer
---@field bg? integer
---@field bold? true
---@field italic? true
---@field underline? true
---@field undercurl? true
---@field strikethrough? true
---@field reverse? true
---@field [integer] string Groups to extend from

---@param t table<string, string | HighlightOpts>
local function create_theme(t)
  vim.g.colors_name = "custom"
  vim.o.background = vim.g.theme_background or "dark"
  vim.o.termguicolors = false

  local hl = vim.api.nvim_set_hl
  local highlights = {}
  local function add_highlight(k, v)
    if v == nil then
      error("highlight not defined in config: " .. k)
    end
    if type(v) == "string" then
      local opts = highlights[v] or add_highlight(v, t[v])
      highlights[k] = opts
      hl(0, k, { link = v })
      return opts
    else
      local opts
      if
        #v ~= 1
        or v.fg
        or v.bg
        or v.bold
        or v.italic
        or v.underline
        or v.undercurl
        or v.strikethrough
        or v.reverse
      then
        opts = {
          ctermfg = v.fg,
          ctermbg = v.bg,
          cterm = {
            bold = v.bold,
            italic = v.italic,
            strikethrough = v.strikethrough,
            underline = v.underline,
            undercurl = v.undercurl,
            reverse = v.reverse,
          },
        }
        for _, name in ipairs(v) do
          local h = highlights[name] or add_highlight(name, t[name])
          opts = {
            ctermfg = opts.ctermfg or h.ctermfg,
            ctermbg = opts.ctermbg or h.ctermbg,
            cterm = {
              bold = opts.cterm.bold or h.cterm.bold,
              italic = opts.cterm.italic or h.cterm.italic,
              strikethrough = opts.cterm.strikethrough or h.cterm.strikethrough,
              underline = opts.cterm.underline or h.cterm.underline,
              undercurl = opts.cterm.undercurl or h.cterm.undercurl,
              reverse = opts.cterm.reverse or h.cterm.reverse,
            },
          }
        end
        hl(0, k, opts)
      else
        opts = highlights[v[1]] or add_highlight(v[1], t[v[1]])
        hl(0, k, { link = v[1] })
      end
      highlights[k] = opts
      return opts
    end
  end
  for k, v in pairs(t) do
    if not highlights[k] then
      add_highlight(k, v)
    end
  end
end

create_theme({
  -- ── Primitives ────────────────────────────────────────────────────────
  -- Constants: cyan/teal slot — distinct from strings and keywords
  Constant = { fg = C4 },
  -- Literals (numbers, chars, booleans): yellow — warm, stands out from text
  Literal = { fg = C3 },
  Number = "Literal",
  Float = "Literal",
  Character = "Literal",
  Boolean = { fg = C9 }, -- bright red — booleans feel decisive
  -- Strings: green slot — classic, easy to scan
  String = { fg = C2 },
  -- String internals
  SpecialChar = { fg = C10 }, -- escape seqs: bright green, related but distinct

  -- ── Identifiers ───────────────────────────────────────────────────────
  Identifier = {}, -- plain text color
  Variable = "Identifier",
  -- Functions: bright cyan/teal — active, prominent
  Function = { fg = C12 },

  -- ── Statements ────────────────────────────────────────────────────────
  -- Keywords: magenta/purple — control flow pops without being alarming
  Statement = { fg = C5 },
  Conditional = "Statement",
  Repeat = "Statement",
  Label = { fg = C13 }, -- bright magenta — label vs keyword distinction
  Operator = { fg = C14 }, -- bright cyan/rose — operators feel active
  Keyword = "Statement",
  Exception = { fg = C9 }, -- bright red — exceptions are errors

  -- ── Preprocessor ──────────────────────────────────────────────────────
  PreProc = { fg = C13 }, -- bright magenta
  Include = { fg = C12 }, -- bright blue — imports feel like paths
  Define = { fg = C5 }, -- magenta
  Macro = { fg = C13 }, -- bright magenta — macros are special
  PreCondit = { fg = C13 },

  -- ── Types ─────────────────────────────────────────────────────────────
  -- Types: blue slot — solid, structural
  Type = { fg = C2, bold = true },
  StorageClass = { fg = C5 }, -- magenta — storage modifiers (static, extern)
  Structure = { fg = C2 }, -- blue — struct/class definitions
  Typedef = { fg = C12 }, -- bright blue — typedef feels like renaming

  -- ── Diagnostics ───────────────────────────────────────────────────────
  Error = { fg = C1 },
  Warning = { fg = C3 },
  Info = { fg = C6 },
  Hint = { fg = C4 },
  Success = { fg = C2 },

  ErrorMsg = { "Error", bold = true },
  WarningMsg = "Warning",
  InfoMsg = "Info",
  HintMsg = "Hint",
  SuccessMsg = "Success",

  DiagnosticError = "Error",
  DiagnosticWarn = "Warning",
  DiagnosticInfo = "Info",
  DiagnosticHint = "Hint",
  DiagnosticOk = "Success",

  DiagnosticUnderlineError = { "DiagnosticError", undercurl = true },
  DiagnosticUnderlineWarn = { "DiagnosticWarn", undercurl = true },
  DiagnosticUnderlineHint = { "DiagnosticHint", undercurl = true },
  DiagnosticUnderlineInfo = { "DiagnosticInfo", undercurl = true },
  DiagnosticUnderlineOk = { "DiagnosticOk", undercurl = true },

  DiagnosticSignError = "DiagnosticError",
  DiagnosticSignWarn = "DiagnosticWarn",
  DiagnosticSignHint = "DiagnosticHint",
  DiagnosticSignInfo = "DiagnosticInfo",
  DiagnosticSignOk = "DiagnosticOk",

  DiagnosticUnnecessary = { fg = C8 }, -- muted/faded
  DiagnosticDeprecated = { fg = C8, strikethrough = true },

  -- ── Spelling ──────────────────────────────────────────────────────────
  SpellBad = { "Error", undercurl = true },
  SpellCap = { "Warning", undercurl = true },
  SpellRare = { "Info", undercurl = true },
  SpellLocal = { "Hint", undercurl = true },

  -- ── Special ───────────────────────────────────────────────────────────
  Special = { fg = C6 }, -- cyan/rose slot
  SpecialKey = { fg = C8 }, -- muted — non-printable chars
  Tag = { fg = C4 }, -- teal
  Delimiter = { fg = C8 }, -- muted — brackets/parens recede
  SpecialComment = { fg = C8, italic = true },

  -- ── Prose / markup ────────────────────────────────────────────────────
  Title = { fg = C2, bold = true },
  Todo = { fg = C11, bold = true }, -- bright yellow — attention
  Note = { fg = C12, bold = true }, -- bright blue
  Question = { fg = C6 },
  Comment = { fg = grey(8), italic = true },

  -- ── Navigation / UI chrome ────────────────────────────────────────────
  Directory = { fg = C4 }, -- teal — directories feel like links

  -- Neutral greys (theme-adaptive via grey())
  GreyBg1 = { bg = grey(1) },
  GreyBg2 = { bg = grey(2) },
  GreyBg3 = { bg = grey(3) },
  GreyBg4 = { bg = grey(8) },

  GreyFg1 = { fg = grey(4) },
  GreyFg2 = { fg = grey(6) },
  GreyFg3 = { fg = grey(12) },

  -- ── Cursor / selection ────────────────────────────────────────────────
  Cursor = { reverse = true },
  Visual = { bg = grey(5) },
  VisualNOS = "Visual",

  CursorLine = "GreyBg4",
  CursorLineNr = { "CursorLine", fg = C7, bold = true },
  CursorLineSign = "CursorLine",
  CursorLineFold = "CursorLine",
  CursorColumn = "CursorLine",
  ColorColumn = { bg = grey(3) },

  -- ── Search ────────────────────────────────────────────────────────────
  Search = { fg = C0, bg = C11 }, -- bright yellow bg, dark fg
  CurSearch = { fg = C0, bg = C3, bold = true },
  IncSearch = "CurSearch",

  -- ── Completion / wildmenu ─────────────────────────────────────────────
  WildMenu = { fg = C0, bg = C4, bold = true },
  MatchParen = { fg = C3, bg = grey(5), bold = true },
  QuickFixLine = { fg = C4, bold = true },

  Pmenu = "GreyBg2",
  PmenuSbar = "GreyBg2",
  PmenuThumb = "GreyBg4",
  PmenuSel = { fg = C15, bg = grey(5), bold = true },
  PmenuKind = { "Pmenu", fg = C4 },
  PmenuKindSel = { "PmenuSel", fg = C12 },
  PmenuExtra = { "Pmenu", fg = C8 },
  PmenuExtraSel = { "PmenuSel", fg = C8 },

  -- ── Tabs / statusline ─────────────────────────────────────────────────
  TabLine = "GreyBg2",
  TabLineSel = { bg = grey(4), fg = C7, bold = true },
  TabLineFill = "GreyBg1",

  StatusLine = { bg = grey(3), fg = C7 },
  StatusLineNC = { bg = grey(1), fg = C8 },

  -- ── Floats / borders ──────────────────────────────────────────────────
  NormalFloat = "GreyBg2",
  FloatBorder = { fg = C8 },
  FloatTitle = { fg = C4, bold = true },

  -- ── Window structure ──────────────────────────────────────────────────
  NonText = "GreyFg1",
  EndOfBuffer = "GreyFg1",
  Whitespace = { fg = grey(3) },
  VertSplit = "GreyFg2",
  WinSeparator = "GreyFg2",
  Border = "GreyFg2",

  -- ── Gutter ────────────────────────────────────────────────────────────
  LineNr = "GreyFg2",
  LineNrAbove = "GreyFg1",
  LineNrBelow = "GreyFg1",
  SignColumn = {},
  FoldColumn = "GreyFg2",
  Folded = { fg = C8, bg = grey(2) },

  -- ── Diff ──────────────────────────────────────────────────────────────
  DiffAdd = { bg = rgb(0, 1, 0) },
  DiffDelete = { bg = rgb(1, 0, 0), fg = C8 },
  DiffChange = { bg = rgb(0, 0, 1) },
  DiffText = { bg = rgb(0, 0, 2), bold = true },

  -- ── Treesitter ────────────────────────────────────────────────────────
  ["@variable"] = "Identifier",
  ["@variable.builtin"] = { fg = C6 }, -- rose/cyan — self, this
  ["@variable.parameter"] = { fg = C7 }, -- plain — params are just vars
  ["@variable.member"] = { fg = C14 }, -- bright cyan — field access

  ["@constant"] = "Constant",
  ["@constant.builtin"] = { fg = C9 }, -- bright red — nil, true, false
  ["@constant.macro"] = { fg = C13 }, -- bright magenta

  ["@string"] = "String",
  ["@string.escape"] = "SpecialChar",
  ["@string.special"] = "SpecialChar",
  ["@string.regexp"] = { fg = C6 }, -- rose — regex is special

  ["@character"] = "Character",
  ["@number"] = "Number",
  ["@float"] = "Float",
  ["@boolean"] = "Boolean",

  ["@function"] = "Function",
  ["@function.builtin"] = { fg = C3, bold = true }, -- yellow bold — builtins distinct from regular fns
  ["@function.macro"] = { fg = C13 },
  ["@function.method"] = { fg = C12 }, -- bright teal

  ["@constructor"] = { fg = C2 }, -- blue/green — constructors ~ types
  ["@operator"] = "Operator",

  ["@keyword"] = "Keyword",
  ["@keyword.import"] = "Include",
  ["@keyword.return"] = { fg = C9 }, -- bright red — return stands out
  ["@keyword.exception"] = "Exception",
  ["@keyword.conditional"] = "Conditional",
  ["@keyword.repeat"] = "Repeat",
  ["@keyword.operator"] = { fg = C14 }, -- and, or, not

  ["@type"] = "Type",
  ["@type.builtin"] = { fg = C2 },
  ["@type.definition"] = { fg = C2, bold = true },

  ["@attribute"] = { fg = C13 }, -- bright magenta — decorators
  ["@property"] = { fg = C14 }, -- bright cyan

  ["@comment"] = "Comment",
  ["@comment.todo"] = "Todo",
  ["@comment.note"] = "Note",
  ["@comment.warning"] = { fg = C3, italic = true },
  ["@comment.error"] = { fg = C1, italic = true },

  ["@tag"] = { fg = C2 }, -- HTML/JSX tags: blue
  ["@tag.attribute"] = { fg = C6 }, -- tag attrs: rose
  ["@tag.delimiter"] = { fg = C8 }, -- <, >, /

  ["@markup.heading"] = { fg = C2, bold = true },
  ["@markup.heading.1"] = { fg = C2, bold = true },
  ["@markup.heading.2"] = { fg = C4, bold = true },
  ["@markup.heading.3"] = { fg = C5, bold = true },
  ["@markup.heading.4"] = { fg = C6, bold = true },
  ["@markup.heading.5"] = { fg = C3, bold = true },
  ["@markup.heading.6"] = { fg = C8, bold = true },
  ["@markup.link"] = { fg = C4, underline = true },
  ["@markup.link.label"] = { fg = C12 },
  ["@markup.link.url"] = { fg = C6, underline = true },
  ["@markup.raw"] = { fg = C3 },
  ["@markup.raw.block"] = { fg = C7 },
  ["@markup.list"] = { fg = C5 },
  ["@markup.list.checked"] = { fg = C2 },
  ["@markup.list.unchecked"] = { fg = C8 },
  ["@markup.italic"] = { italic = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.strikethrough"] = { strikethrough = true },

  -- ── Punctuation ───────────────────────────────────────────────────────
  ["@punctuation.bracket"] = { fg = grey(12) }, -- ( ) [ ] { } — recede
  ["@punctuation.delimiter"] = { fg = grey(12) }, -- , ; : — recede
  ["@punctuation.special"] = { fg = C5 }, -- $( ) interpolation — magenta pop

  -- ── String specials ───────────────────────────────────────────────────
  -- @string.special already links to SpecialChar (C10) above; add subtypes:
  ["@string.special.symbol"] = { fg = C11, bold = true }, -- make/ruby symbols, var assignment LHS — bright yellow
  ["@string.special.path"] = { fg = C4, underline = true }, -- file paths
  ["@string.special.url"] = { fg = C4, underline = true }, -- URLs

  -- ── Character special ─────────────────────────────────────────────────
  ["@character.special"] = { fg = C13, bold = true }, -- make @ prefix, $@, $< etc — bright magenta

  -- ── Function calls ────────────────────────────────────────────────────
  ["@function.call"] = { fg = C7 }, -- generic command words stay plain
  ["@function.method.call"] = { fg = C4 }, -- method calls: teal

  -- ── Keyword variants ──────────────────────────────────────────────────
  ["@keyword.function"] = { fg = C5 }, -- 'function' keyword (bash, lua)
  ["@keyword.directive"] = { fg = C13 }, -- shebangs, preprocessor directives
  ["@keyword.directive.define"] = { fg = C13 },

  -- Language-specific overrides
  ["@constructor.lua"] = {},
  ["@variable.member.go"] = { fg = C7 }, -- go fields plain

  -- ── LSP semantic tokens ───────────────────────────────────────────────
  ["@lsp.type.class"] = "Type",
  ["@lsp.type.enum"] = "Type",
  ["@lsp.type.interface"] = { fg = C4 },
  ["@lsp.type.struct"] = "Structure",
  ["@lsp.type.parameter"] = { fg = C7 },
  ["@lsp.type.variable"] = "Identifier",
  ["@lsp.type.property"] = { fg = C14 },
  ["@lsp.type.enumMember"] = "Constant",
  ["@lsp.type.function"] = "Function",
  ["@lsp.type.method"] = { fg = C12 },
  ["@lsp.type.macro"] = { fg = C13 },
  ["@lsp.type.decorator"] = { fg = C13 },
  ["@lsp.type.namespace"] = { fg = C7 },
  ["@lsp.type.comment"] = "Comment",
  ["@lsp.mod.deprecated"] = { fg = C8, strikethrough = true },
  ["@lsp.mod.readonly"] = { fg = C4 },
  ["@lsp.mod.static"] = { bold = true },

  -- ── fugitive ──────────────────────────────────────────────────────────
  FugitiveblameHash = { fg = C4 },
  FugitiveblameBoundary = { fg = C5 },
  FugitiveblameUncommitted = "Comment",
  FugitiveblameNotCommittedYet = "Comment",
  FugitiveblameTime = "GreyFg3",
  FugitiveblameLineNumber = "LineNr",
  FugitiveblameOriginalFile = { fg = C2 },
  FugitiveblameOriginalLineNumber = "LineNr",
  FugitiveblameDelimiter = "GreyFg1",
  FugitiveblameShort = "FugitiveblameDelimiter",

  -- ── gitsigns ──────────────────────────────────────────────────────────
  GitSignsAdd = { fg = C2 },
  GitSignsChange = { fg = C3 },
  GitSignsDelete = { fg = C1 },
  GitSignsChangedelete = { fg = C3 },
  GitSignsTopdelete = { fg = C1 },
  GitSignsUntracked = { fg = C8 },

  GitSignsAddInline = { bg = rgb(0, 1, 0) },
  GitSignsChangeInline = { bg = rgb(0, 0, 1) },
  GitSignsDeleteInline = { bg = rgb(1, 0, 0) },

  -- ── mini.starter ──────────────────────────────────────────────────────
  MiniStarterHeader = { fg = C4, bold = true },
  MiniStarterFooter = { "Comment" },
  MiniStarterSection = { fg = C6 },
  MiniStarterItemBullet = { fg = C4 },
  MiniStarterItemPrefix = { "WarningMsg", bold = true },
  MiniStarterInactive = { "Comment" },
  MiniStarterQuery = { "WarningMsg", bold = true },
  MiniStarterCurrent = { "WarningMsg", bold = true },

  -- ── mini.statusline ───────────────────────────────────────────────────
  MiniStatuslineModeNormal = { bg = C4, fg = C0, bold = true },
  MiniStatuslineModeInsert = { bg = C2, fg = C0, bold = true },
  MiniStatuslineModeVisual = { bg = C5, fg = C15, bold = true },
  MiniStatuslineModeReplace = { bg = C1, fg = C15, bold = true },
  MiniStatuslineModeCommand = { bg = C3, fg = C0, bold = true },
  MiniStatuslineModeOther = { bg = C6, fg = C0, bold = true },
  MiniStatuslineDevinfo = { bg = grey(3), fg = grey(14) },
  MiniStatuslineFilename = { bg = grey(3), fg = grey(14) },
  MiniStatuslineFileinfo = { bg = grey(3), fg = grey(14) },
  MiniStatuslineInactive = { bg = grey(1), fg = C8 },
})
