return {
  {
    -- The plugin location on GitHub
    "vimwiki/vimwiki",
    -- The event that triggers the plugin
    -- The keys that trigger the plugin
    keys = { "<leader>ww", "<leader>wt" },
    -- The configuration for the plugin
    init = function()
      vim.g.vimwiki_list = {
        {
          -- Here will be the path for your wiki
          path = "~/vimwiki/",
          -- The syntax for the wiki
          syntax = "markdown",
          ext = "md",
        },
      }
    end,
  },
  {
    'mrcjkb/rustaceanvim',
    version = '^6', -- Recommended
    lazy = false, -- This plugin is already lazy
  },
  {
    'mfussenegger/nvim-dap',
    lazy = false;
  },
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "reedes/vim-pencil",
    lazy = false,
  },
  {
    "junegunn/goyo.vim",
    lazy = false,
  },
  {
    "junegunn/limelight.vim",
    lazy = false,
  },
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "html",
    },
    config = function ()
      require("nvim-ts-autotag").setup()
    end
  },
  {
    'brianhuster/live-preview.nvim',
    dependencies = {
        -- You can choose one of the following pickers
        'nvim-telescope/telescope.nvim',
        'ibhagwan/fzf-lua',
        'echasnovski/mini.pick',
		'folke/snacks.nvim',
    },
  },
  {
      "nvim-tree/nvim-tree.lua",
      opts = {
        filters = {
          git_ignored = false,
        }
      }
  },
  {
      "mason-org/mason.nvim",
      opts = {ensure_installed = {
        "clangd"
      }
    ,}
  },
  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = {
  		ensure_installed = {
  			"vim", "lua", "vimdoc",
       "html", "css","javascript",
        "typescript","tsx","go","rust"
  		},
  	},
  },
}
