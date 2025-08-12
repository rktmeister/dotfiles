return {
  {
    "meanderingexile/nostromo-ui.nvim",
    enabled = false, -- Remove this line to enable the plugin
    lazy = false,
    priority = 1000,
    config = function()
      require("nostromo-ui").setup {
        -- (note: if your configuration sets vim.o.background the following option will do nothing!)
        theme = "dark", -- String: 'dark' or 'light', determines the colorscheme used
        transparent = false, -- Boolean: Sets the background to transparent
        italics = {
          comments = true, -- Boolean: Italicizes comments
          keywords = true, -- Boolean: Italicizes keywords
          functions = true, -- Boolean: Italicizes functions
          strings = true, -- Boolean: Italicizes strings
          variables = true, -- Boolean: Italicizes variables
        },
        overrides = {}, -- A dictionary of group names, can be a function returning a dictionary or a table.
      }
      vim.cmd "colorscheme nostromo-ui"
    end,
  },
}
