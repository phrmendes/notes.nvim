--- Type definitions for notes.nvim
---
--- All `@class` definitions live here so they can be consulted from a single place.
--- Other files reference types by name; LuaLS resolves them via the workspace.

---@class UserConfig
---@field path string Path to the notes directory
---@field picker string Picker backend name
---@field journal NotesJournalConfig | nil Journal configuration

---@class PickerBackend
---@field files fun(items: string[], dir: string, on_choice: fun(choice: string|nil))
---@field grep fun(dir: string, glob: string, on_choice: fun(choice: string|nil))

---@class NotesJournalConfig
---@field path string | nil
---@field title_format string
