-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well.

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

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
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
      icons = { expanded = '', collapsed = '', current_frame = '*' },
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
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

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

    -- NOTE: OK
    -- Javascript config
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = { '${env:HOME}/AppData/Local/nvim/js-debug/src/dapDebugServer.js', '${port}' },
      },
    }
    -- dap.adapters['pwa-chrome'] = {
    --   type = 'server',
    --   host = 'localhost',
    --   port = '${port}',
    --   executable = {
    --     command = 'node',
    --     args = { '${env:HOME}/AppData/Local/nvim/js-debug/src/dapDebugServer.js', '${port}' },
    --   },
    -- }
    -- dap.adapters.node = {}
    -- dap.adapters.chrome = {
    --   type = 'executable',
    --   command = 'node',
    --   args = { '${env:HOME}/AppData/Local/nvim/vscode-chrome-debug/out/src/chromeDebug.js' },
    -- }

    -- Chrome installation from https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#javascript-chrome
    local chromeConfig = {
      name = 'Chrome',
      type = 'chrome',
      request = 'attach',
      program = '${file}',
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      protocol = 'inspector',
      port = 9222,
      webRoot = '${workspaceFolder}',
    }

    dap.configurations.javascriptreact = {
      chromeConfig,
    }
    dap.configurations.typescriptreact = {
      chromeConfig,
    }

    dap.configurations.javascript = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch File',
        program = '${file}',
        cwd = '${workspaceFolder}',
      },
      -- {
      --   type = 'pwa-chrome',
      --   request = 'launch',
      --   name = 'Launch Chrome',
      --   url = 'http://localhost:3000',
      --   sourceMaps = true,
      -- },
      chromeConfig,
    }
  end,
}
