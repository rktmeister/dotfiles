---@type LazySpec
return {
  "nvim-telescope/telescope.nvim",
  opts = function(_, opts)
    opts = opts or {}
    opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
      winblend = 0, -- keep floats opaque like Snacks { win = { blend = 0 } }
      selection_caret = "▸ ",
      borderchars = { -- clean, matches Snacks minimal border vibe
        prompt = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        results = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      },
    })
    return opts
  end,
  config = function(_, opts)
    require("telescope").setup(opts)

    local function apply()
      -- Gruvbox gray row, to match your Snacks picker
      local sel_bg = "#928374" -- gruvbox Gray
      local sel_fg = "#1d2021" -- hard bg for contrast

      -- current row in results list
      vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = sel_bg, fg = sel_fg, bold = true })
      vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { bg = sel_bg, fg = sel_fg })

      -- make the window visuals align with common float styling
      local float_border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })
      local border_fg = (float_border and float_border.fg) or nil

      if border_fg then
        vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = border_fg })
        vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = border_fg })
        vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = border_fg })
        vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = border_fg })
      end

      -- optional - make matches pop a bit, similar to how you likely set SnacksPickerMatch
      -- vim.api.nvim_set_hl(0, "TelescopeMatching", { bold = true, underline = true })
    end

    apply()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("MatchSnacksAndTelescope", { clear = true }),
      callback = apply,
    })
  end,
}
