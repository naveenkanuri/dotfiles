return {
  colorscheme = "everforest",
  colorscheme = "catppuccin",
  diagnostics = {
    virtual_text = true,
    underline = true,
  },
  -- Configure require("lazy").setup() options
  lazy = {
    defaults = { lazy = true },
    performance = {
      rtp = {
        -- customize default disabled vim plugins
        disabled_plugins = { "tohtml", "gzip", "matchit", "zipPlugin", "netrwPlugin", "tarPlugin" },
      },
    },
  },
}
