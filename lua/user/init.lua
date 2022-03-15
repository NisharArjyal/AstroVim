local status = require "core.status"

local config = {

  -- Set colorscheme
  colorscheme = "default_theme",

  default_theme = {
    diagnostics_style = "italic",
  },

  -- Add plugins
  plugins = {
    -- Change Packer config itself:
    packer = {
      compile_path = vim.fn.stdpath "cache" .. "/lua/packer_compiled.lua",
    },
    -- Change plugins to install:
    init = function(plugins)
      local result = {
        -- Extended file type support
        { "sheerun/vim-polyglot" },

        -- Cursor Jump Highlight
        {
          "rainbowhxch/beacon.nvim",
          config = function()
            require('beacon').setup({
              size = 160,
              minimal_jump = 5,
            })
          end,
        },

        -- LSP
        {
          "ray-x/lsp_signature.nvim",
          config = function()
            require("lsp_signature").setup()
          end,
        },

        -- Properly paste code into vim:
        { "ConradIrwin/vim-bracketed-paste" },

        -- My slint plugin
        { "slint-ui/vim-slint" },

        -- DAP:
        { "mfussenegger/nvim-dap" },
        {
          "rcarriga/nvim-dap-ui",
          requires = { "nvim-dap", "rust-tools.nvim" },
          config = function()
            local dapui = require "dapui"
            dapui.setup {}

            local dap = require "dap"
            dap.listeners.after.event_initialized["dapui_config"] = function()
              dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
              dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
              dapui.close()
            end
          end,
        },
        {
          "Pocco81/DAPInstall.nvim",
          config = function()
            require("dap-install").setup {}
          end,
        },
        {
          "mfussenegger/nvim-dap-python",
        },
        -- Rust support
        {
          "simrat39/rust-tools.nvim",
          requires = { "nvim-lspconfig", "nvim-lsp-installer", "nvim-dap", "Comment.nvim", "plenary.nvim" },
          -- Is configured via the server_registration_override installed below!
        },
        {
          "Saecki/crates.nvim",
          after = "nvim-cmp",
          config = function()
            require("crates").setup()

            local cmp = require "cmp"
            local config = cmp.get_config()
            table.insert(config.sources, { name = "crates", priority=1100 })
            cmp.setup(config)
          end,
        },
        {
          "hrsh7th/cmp-calc",
          after = "nvim-cmp",
          config = function()
            require("crates").setup()

            local cmp = require "cmp"
            local config = cmp.get_config()
            table.insert(config.sources, { name = "calc", priority=100 })
            cmp.setup(config)
          end,
        },

        -- Tools
        { "tpope/vim-repeat" },
        { "tpope/vim-surround" },
        { "tpope/vim-fugitive" },

        {
          "ggandor/lightspeed.nvim",
          config = function()
            require("lightspeed").setup {}
          end,
        },

        -- Text objects
        { "bkad/CamelCaseMotion" },
        {
          "ziontee113/syntax-tree-surfer",
          after = "nvim-treesitter",
        },

        -- Github:
        {
          'pwntester/octo.nvim',
          after = { 'telescope.nvim', },
          config = function ()
            require"octo".setup()
          end
        },
      }

      -- disable fzf native plugin as that fails to build for me
      plugins["nvim-telescope/telescope-fzf-native.nvim"] = nil

      -- disable delayed loading of all default plugins:
      for _, plugin in pairs(plugins) do
        -- disable lazy loading
        -- plugin["cmd"] = nil
        -- plugin["event"] = nil
        -- plugin["after"] = nil
        -- disable special stuff done on startup (like build TS plugins!)
        -- plugin["run"] = nil

        table.insert(result, plugin)
      end

      return result
    end,
    -- Now configure some of the default plugins:
    cmp = function(config)
      local cmp_ok, cmp = pcall(require, "cmp")
      local luasnip_ok, luasnip = pcall(require, "luasnip")

      if cmp_ok and luasnip_ok then
        config.mapping["<CR>"] = cmp.mapping.confirm()
        config.mapping["<Tab>"] = cmp.mapping(
          function(fallback)
            if luasnip.expandable() then
              luasnip.expand()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end,
	        {
            "i",
            "s",
          }
      	)
        config.mapping["<S-Tab>"] = cmp.mapping(
	        function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end,
	        {
            "i",
            "s",
          }
	      )
      end
      return config
    end,
    lualine = {
      sections = {
        lualine_a = {
          { "filename", file_status = true, path = 1, full_path = true, shorten = false },
          -- { "mode", padding = { left = 1, right = 1 } },
        },
        lualine_b = {
          "filetype",
          { "branch", icon = "" },
        },
        lualine_c = {
          { "diff", symbols = { added = " ", modified = "柳", removed = " " } },
          { "diagnostics", sources = { "nvim_diagnostic" } },
        },
        lualine_x = {
          status.lsp_progress,
        },
        lualine_y = {
          { status.lsp_name, icon = " " },
          status.treesitter_status,
        },
        lualine_z = {
          { "progress" },
          { "location" },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    },
    luasnip = {
      vscode_snippet_paths = { paths = "/home/extra/.config/nvim-data/snippets" },
    },
    treesitter = {
      ensure_installed = {},
    },
  },

  lsp = {
    server_registration = function(server, server_opts)
      -- Special code for rust.tools.nvim!
      if server.name == "rust_analyzer" then
        local extension_path = vim.fn.stdpath "data" .. "/dapinstall/codelldb/extension"
        local codelldb_path = extension_path .. "/adapter/codelldb"
        local liblldb_path = extension_path .. "/lldb/lib/liblldb.so"

        require("rust-tools").setup {
          server = server_opts,
          -- dap = {
          --   adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
          -- },
          tools = {
            inlay_hints = {
              parameter_hints_prefix = "  ",
              other_hints_prefix = "  ",
            },
          },
        }
      else
        server:setup(server_opts)
      end
    end,
  },

  -- Disable default plugins
  enabled = {
    bufferline = false,
    neo_tree = false,
    lualine = true,
    lspsaga = true,
    gitsigns = true,
    colorizer = true,
    toggle_term = false,
    comment = true,
    symbols_outline = true,
    indent_blankline = true,
    dashboard = false,
    which_key = false,
    neoscroll = false,
    ts_rainbow = true,
    ts_autotag = true,
  },

   -- null-ls configuration
  ["null-ls"] = function()
    -- Formatting and linting
    -- https://github.com/jose-elias-alvarez/null-ls.nvim
    local status_ok, null_ls = pcall(require, "null-ls")
    if not status_ok then
      return
    end

    -- Check supported formatters
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    local formatting = null_ls.builtins.formatting

    -- Check supported linters
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
    local diagnostics = null_ls.builtins.diagnostics

    null_ls.setup {
      debug = false,
      sources = {
        -- Set a formatter
        formatting.rufo,
        -- Set a linter
        diagnostics.rubocop,
      },
      -- NOTE: You can remove this on attach function to disable format on save
      on_attach = function(client)
        if client.resolved_capabilities.document_formatting then
          vim.api.nvim_create_autocmd("BufWritePre",  {
            desc = "Auto format before save",
            pattern = "<buffer>",
            callback = vim.lsp.buf.formatting_sync,
          })
        end
      end,
    }
  end,

  polish = function()
    local opts = { noremap = true, silent = true }
    local map = vim.api.nvim_set_keymap
    local unmap = vim.api.nvim_del_keymap

    vim.opt.colorcolumn = "80,100,9999"
    vim.opt.scrolloff = 15
    vim.opt.sidescrolloff = 15

    vim.opt.numberwidth = 4

    vim.opt.undofile = false

    vim.opt.timeoutlen = 1000 -- I am slow at typing:-/
    vim.opt.clipboard = "" -- the default is *SLOW* on my system

    -- Undo some AstroVim mappings:
    unmap("n", "<C-q>")
    unmap("n", "<C-s>")
    unmap("n", "<leader>gd")

    map("n", "fm", ":lua vim.lsp.buf.formatting()<cr>", opts)
    map("n", "<leader>D", ":Telescope lsp_type_definitions<cr>", opts)

    -- Telescope mappings:
    map("n", "<leader>faf", ":Telescope find_files hidden=true no_ignore=true<cr>", opts)

    map("n", "<leader>fS", ":Telescope lsp_workspace_symbols<cr>", opts)
    map("n", "<leader>fs", ":Telescope lsp_document_symbols<cr>", opts)
    -- map("n", "<leader>fq", ":Telescope quickfix<cr>", opts)
    map("n", "<leader>fr", ":Telescope lsp_references<cr>", opts)
    map("n", "<leader>fs", ":Telescope lsp_document_symbols<cr>", opts)
    map("n", "<leader>fS", ":Telescope lsp_workspace_symbols<cr>", opts)

    map("n", "<leader>fgi", ":Telescope gh issues<cr>", opts)
    map("n", "<leader>fgp", ":Telescope gh pull_request<cr>", opts)
    map("n", "<leader>fgg", ":Telescope gh gist<cr>", opts)

    map("n", "<leader>fB", ":Telescope file_browser<cr>", opts)

    -- Crates mappings:
    map("n", "<leader>Ct", ":lua require('crates').toggle()<cr>", opts)
    map("n", "<leader>Cr", ":lua require('crates').reload()<cr>", opts)
    map("n", "<leader>CU", ":lua require('crates').upgrade_crate()<cr>", opts)
    map("v", "<leader>CU", ":lua require('crates').upgrade_crates()<cr>", opts)
    map("n", "<leader>CA", ":lua require('crates').upgrade_all_crates()<cr>", opts)

    -- DAP mappings:
    map("n", "<F5>", ":lua require('dap').continue()<cr>", opts)
    map("n", "<F10>", ":lua require('dap').step_over()<cr>", opts)
    map("n", "<F11>", ":lua require('dap').step_into()<cr>", opts)
    map("n", "<F12>", ":lua require('dap').step_out()<cr>", opts)
    map("n", "<leader>bp", ":lua require('dap').toggle_breakpoint()<cr>", opts)
    map("n", "<leader>Bp", ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", opts)
    map("n", "<leader>lp", ":lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Logpoint message: '))<cr>", opts)
    map("n", "<leader>rp", ":lua require('dap').repl.open()<cr>", opts)
    map("n", "<leader>RR", ":lua require('dap').run_last()<cr>", opts)
    map("n", "<leader>XX", ":lua require('dap').terminate()<cr>", opts)
    map("n", "<leader>du", ":lua require('dap').up()<cr>", opts)
    map("n", "<leader>dd", ":lua require('dap').down()<cr>", opts)

    -- Allow gf to work for non-existing files
    map("n", "gf", ":edit <cfile><cr>", opts)
    map("v", "gf", ":edit <cfile><cr>", opts)
    map("o", "gf", ":edit <cfile><cr>", opts)

    map("n", "<f8>", ":cprev<cr>", opts)
    map("n", "<f9>", ":cnext<cr>", opts)

    -- Syntax Tree Surfer

    -- Normal Mode Swapping
    map("n", "vd", '<cmd>lua require("syntax-tree-surfer").move("n", false)<cr>', opts)
    map("n", "vu", '<cmd>lua require("syntax-tree-surfer").move("n", true)<cr>', opts)
    -- .select() will show you what you will be swapping with .move(), you'll get used to .select() and .move() behavior quite soon!
    map("n", "vx", '<cmd>lua require("syntax-tree-surfer").select()<cr>', opts)
    -- .select_current_node() will select the current node at your cursor
    map("n", "vn", '<cmd>lua require("syntax-tree-surfer").select_current_node()<cr>', opts)

    -- NAVIGATION: Only change the keymap to your liking. I would not recommend changing anything about the .surf() parameters!
    map("x", "J", '<cmd>lua require("syntax-tree-surfer").surf("next", "visual")<cr>', opts)
    map("x", "K", '<cmd>lua require("syntax-tree-surfer").surf("prev", "visual")<cr>', opts)
    map("x", "H", '<cmd>lua require("syntax-tree-surfer").surf("parent", "visual")<cr>', opts)
    map("x", "L", '<cmd>lua require("syntax-tree-surfer").surf("child", "visual")<cr>', opts)

    -- SWAPPING WITH VISUAL SELECTION: Only change the keymap to your liking. Don't change the .surf() parameters!
    map("x", "<A-j>", '<cmd>lua require("syntax-tree-surfer").surf("next", "visual", true)<cr>', opts)
    map("x", "<A-k>", '<cmd>lua require("syntax-tree-surfer").surf("prev", "visual", true)<cr>', opts)

    -- Beacon
    map("n", "n", "n:Beacon<cr>", opts)
    map("n", "N", "N:Beacon<cr>", opts)
    map("n", "*", "*:Beacon<cr>", opts)
    map("n", "#", "#:Beacon<cr>", opts)
  end
}

return config
