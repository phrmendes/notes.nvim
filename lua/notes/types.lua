--- Type definitions for notes.nvim
---
--- All `@class` definitions live here so they can be consulted from a single place.
--- Other files reference types by name; LuaLS resolves them via the workspace.

---@class UserConfig
---@field path string Path to the notes directory
---@field picker string Picker backend name
---@field lsp NotesLspConfig | nil LSP configuration
---@field journal NotesJournalConfig | nil Journal configuration

---@class PickerBackend
---@field files fun(items: string[], dir: string, on_choice: fun(choice: string|nil))
---@field grep fun(dir: string, glob: string, on_choice: fun(choice: string|nil))

---@class NotesJournalConfig
---@field path string | nil
---@field title_format string

---@class NotesLtexPlusConfig
---@field enabled? boolean Enable ltex-ls-plus LSP on setup (default: true)
---@field language? string Initial language code (default: "en-US")
---@field languages? string[] Languages available in the picker

---@class NotesMarksmanConfig
---@field enabled? boolean Enable marksman LSP on setup (default: true)

---@class NotesLspConfig
---@field marksman boolean | NotesMarksmanConfig Auto-enable marksman LSP on setup (default: true)
---@field ltex_plus boolean | NotesLtexPlusConfig Auto-enable ltex-ls-plus LSP on setup (default: true)
