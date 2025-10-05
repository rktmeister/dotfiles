---@type LazySpec
return {
  "folke/snacks.nvim",
  config = function(_, opts)
    require("snacks").setup(opts)

    local function apply()
      local bg = "#3c3836" -- Gruvbox bg1
      local fg = "#ebdbb2" -- Gruvbox fg1
      vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = bg })
      vim.api.nvim_set_hl(0, "SnacksPickerListSelected", { bg = bg, fg = fg, bold = true })
      vim.api.nvim_set_hl(0, "SnacksPickerPreviewCursorLine", { bg = bg })
    end

    apply()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("SnacksPickerHL", { clear = true }),
      callback = apply,
    })
  end,
}
