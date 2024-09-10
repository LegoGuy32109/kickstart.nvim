-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well.

local js_languages = {
  'typescript',
  'typescriptreact',
  'javascriptreact',
  'javascript',
}

return {
  'mfussenegger/nvim-dap',

  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    {
      'microsoft/vscode-js-debug',
      -- I had to do this myself, keeping here for reference
      build = 'npm i --legacy-peer-deps && npx gulp vsDebugServerBundle && rename dist out',
    },
    {
      'mxsdev/nvim-dap-vscode-js',
      config = function()
        ---@diagnostic disable-next-line missing-required-fields
        require('dap-vscode-js').setup {
          debugger_path = vim.fn.resolve(vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug'),
          -- Command to launch debug server, takes precedence over "node_path" and "debugger_path"
          -- debugger_cmd = {"js-debug-adapter"},
          --
          -- Adapters to register to nvim-dap
          adapters = {
            'node',
            'chrome',
            'pwa-node',
            'pwa-chrome',
            'pwa-msedge',
            'pwa-extensionHost',
            'node-terminal',
          },

          -- Path for file logging
          -- log_file_path = "./dap_vscode_js.log",
          -- False to disable logging
          -- log_file_level = false,
          -- Logging level for output to console, set to false to disable console output
          -- log_console_level = vim.log.levels.ERROR,
        }
      end,
    },
    -- Helps read json files for launch.json I guess
    {
      'Joakker/lua-json5',
      build = './install sh',
    },
  },

  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        -- 'delve',
      },
    }

    vim.keymap.set('n', '<F5>', function()
      if vim.fn.filereadable '.vscode/launch.json' then
        local dapVscode = require 'dap.ext.vscode'
        dapVscode.load_launchjs(nil, {
          ['pwa-node'] = js_languages,
          ['node'] = js_languages,
          ['chrome'] = js_languages,
          ['pwa-chrome'] = js_languages,
        })
      end
      dap.continue()
    end, { desc = 'Debug: Start/Continue' })
    -- TODO: Restart?
    -- vim.keymap.set('n', '<C-F5>', dap., { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Conditional Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      icons = { expanded = '', collapsed = '', current_frame = '>' },
      ---@diagnostic disable-next-line: missing-fields
      controls = {
        icons = {
          pause = '',
          play = '▶',
          step_into = '',
          step_over = '',
          step_out = '',
          step_back = '',
          run_last = '▶▶',
          terminate = '',
          disconnect = '',
        },
      },
      mappings = {},
      element_mappings = {},
      expand_lines = true,
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Toggle dap-ui' })
    vim.keymap.set({ 'n', 'v' }, '<leader>k', dapui.eval, { desc = 'Evaluate Expression' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    for _, language in ipairs(js_languages) do
      dap.configurations[language] = {
        -- Debug single nodejs files
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
        },
        -- Debug nodejs process (add --inspect or --inspect-brk)
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
        },
        -- Debug web applications (client side)
        {
          type = 'pwa-chrome',
          request = 'launch',
          name = 'Launch & Debug Chrome',
          url = function()
            local co = coroutine.running()
            return coroutine.create(function()
              vim.ui.input({
                prompt = 'Enter Url: ',
                default = 'http://localhost:3000',
              }, function(url)
                if url == nil or url == '' then
                  return
                else
                  coroutine.resume(co, url)
                end
              end)
            end)
          end,
          webRoot = '${workspaceFolder}',
          skipFiles = { '<node_internals>/* */*.js' },
          protocol = 'inspector',
          sourceMaps = true,
          userDataDir = false,
        },
        {
          name = '========== ⬇ launch.json configs ⬇ ==========',
          type = '',
          request = 'launch',
        },
      }
    end

    -- GDScript config
    dap.adapters.godot = {
      type = 'server',
      host = '127.0.0.1',
      port = 6006,
    }

    dap.configurations.gdscript = {
      {
        type = 'godot',
        request = 'launch',
        name = 'Launch Main Scene',
        project = '${workspaceFolder}',
      },
    }
  end,
}
