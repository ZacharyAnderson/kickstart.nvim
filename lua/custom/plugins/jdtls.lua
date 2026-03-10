return {
  {
    'mfussenegger/nvim-jdtls',
    ft = 'java',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      local jdtls = require 'jdtls'
      local home = os.getenv 'HOME'

      -- Find root of project (looks for Bazel WORKSPACE or BUILD files)
      local root_markers = { 'WORKSPACE', 'WORKSPACE.bazel', 'BUILD', 'BUILD.bazel', '.git' }
      local root_dir = require('jdtls.setup').find_root(root_markers)

      -- Data directory for jdtls workspace storage
      local workspace_dir = home .. '/.local/share/nvim/jdtls-workspace/' .. vim.fn.fnamemodify(root_dir, ':p:h:t')

      -- Get the Mason install path for jdtls
      local mason_registry = require 'mason-registry'
      local jdtls_pkg = mason_registry.get_package 'jdtls'
      local jdtls_path = jdtls_pkg:get_install_path()

      -- Determine OS
      local os_config = 'linux'
      if vim.fn.has 'mac' == 1 then
        os_config = 'mac'
      elseif vim.fn.has 'win32' == 1 then
        os_config = 'win'
      end

      -- jdtls configuration
      local config = {
        cmd = {
          'java',
          '-Declipse.application=org.eclipse.jdt.ls.core.id1',
          '-Dosgi.bundles.defaultStartLevel=4',
          '-Declipse.product=org.eclipse.jdt.ls.core.product',
          '-Dlog.protocol=true',
          '-Dlog.level=ALL',
          '-Xmx8G',
          '--add-modules=ALL-SYSTEM',
          '--add-opens',
          'java.base/java.util=ALL-UNNAMED',
          '--add-opens',
          'java.base/java.lang=ALL-UNNAMED',
          -- Bazel-specific JVM flags for compiler access
          '--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED',
          '--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED',
          '--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED',
          '--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED',
          '--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED',
          '--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED',
          '--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED',
          '--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED',
          '--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED',
          '--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED',
          '-jar',
          vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
          '-configuration',
          jdtls_path .. '/config_' .. os_config,
          '-data',
          workspace_dir,
        },

        root_dir = root_dir,

        -- Load Bazel-generated classpath if available
        on_init = function(client)
          local classpath_file = home .. '/.cache/jdtls-bazel/classpath.txt'
          local sources_file = home .. '/.cache/jdtls-bazel/sources.txt'

          local function file_exists(path)
            local f = io.open(path, 'r')
            if f then
              f:close()
              return true
            end
            return false
          end

          local function read_lines(path)
            local lines = {}
            for line in io.lines(path) do
              if line ~= '' then
                table.insert(lines, line)
              end
            end
            return lines
          end

          if file_exists(classpath_file) then
            local classpath = read_lines(classpath_file)
            vim.notify('Loaded ' .. #classpath .. ' JARs from Bazel classpath', vim.log.levels.INFO)
          else
            vim.notify(
              'No Bazel classpath found. Run: bazel-jdtls-classpath //domains/event-platform/...',
              vim.log.levels.WARN
            )
          end
        end,

        settings = {
          java = {
            -- Use Bazel-generated classpath
            project = {
              referencedLibraries = (function()
                local classpath_file = home .. '/.cache/jdtls-bazel/classpath.txt'
                local f = io.open(classpath_file, 'r')
                if f then
                  local jars = {}
                  for line in f:lines() do
                    if line ~= '' and line:match('%.jar$') then
                      table.insert(jars, line)
                    end
                  end
                  f:close()
                  return jars
                end
                return {}
              end)(),
              sourcePaths = (function()
                local sources_file = home .. '/.cache/jdtls-bazel/sources.txt'
                local f = io.open(sources_file, 'r')
                if f then
                  local sources = {}
                  for line in f:lines() do
                    if line ~= '' then
                      table.insert(sources, line)
                    end
                  end
                  f:close()
                  return sources
                end
                return {}
              end)(),
            },
            eclipse = {
              downloadSources = true,
            },
            configuration = {
              updateBuildConfiguration = 'interactive',
            },
            maven = {
              downloadSources = true,
            },
            implementationsCodeLens = {
              enabled = true,
            },
            referencesCodeLens = {
              enabled = true,
            },
            references = {
              includeDecompiledSources = true,
            },
            format = {
              enabled = true,
              settings = {
                url = home .. '/.config/nvim/lang-servers/intellij-java-google-style.xml',
                profile = 'GoogleStyle',
              },
            },
          },
          signatureHelp = { enabled = true },
          completion = {
            favoriteStaticMembers = {
              'org.hamcrest.MatcherAssert.assertThat',
              'org.hamcrest.Matchers.*',
              'org.hamcrest.CoreMatchers.*',
              'org.junit.jupiter.api.Assertions.*',
              'java.util.Objects.requireNonNull',
              'java.util.Objects.requireNonNullElse',
              'org.mockito.Mockito.*',
            },
            importOrder = {
              'java',
              'javax',
              'com',
              'org',
            },
          },
          extendedClientCapabilities = jdtls.extendedClientCapabilities,
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          codeGeneration = {
            toString = {
              template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
            },
            useBlocks = true,
          },
        },

        flags = {
          allow_incremental_sync = true,
        },

        init_options = {
          bundles = {},
        },
      }

      -- This starts the jdtls language server
      jdtls.start_or_attach(config)

      -- Setup keymaps
      local opts = { buffer = vim.api.nvim_get_current_buf() }
      vim.keymap.set('n', '<leader>co', jdtls.organize_imports, vim.tbl_extend('force', opts, { desc = '[C]ode [O]rganize imports' }))
      vim.keymap.set('n', '<leader>cv', jdtls.extract_variable, vim.tbl_extend('force', opts, { desc = '[C]ode Extract [V]ariable' }))
      vim.keymap.set('v', '<leader>cv', [[<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>]], { desc = '[C]ode Extract [V]ariable' })
      vim.keymap.set('n', '<leader>cm', jdtls.extract_method, vim.tbl_extend('force', opts, { desc = '[C]ode Extract [M]ethod' }))
      vim.keymap.set('v', '<leader>cm', [[<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>]], { desc = '[C]ode Extract [M]ethod' })
      vim.keymap.set('n', '<leader>ct', jdtls.test_class, vim.tbl_extend('force', opts, { desc = '[C]ode [T]est class' }))
      vim.keymap.set('n', '<leader>cn', jdtls.test_nearest_method, vim.tbl_extend('force', opts, { desc = '[C]ode Test [N]earest method' }))

      -- Register keymaps with which-key for better visibility
      local status_ok, which_key = pcall(require, 'which-key')
      if status_ok then
        which_key.add({
          { '<leader>co', desc = '[O]rganize imports', buffer = vim.api.nvim_get_current_buf() },
          { '<leader>cv', desc = 'Extract [V]ariable', buffer = vim.api.nvim_get_current_buf(), mode = { 'n', 'v' } },
          { '<leader>cm', desc = 'Extract [M]ethod', buffer = vim.api.nvim_get_current_buf(), mode = { 'n', 'v' } },
          { '<leader>ct', desc = '[T]est class', buffer = vim.api.nvim_get_current_buf() },
          { '<leader>cn', desc = 'Test [N]earest method', buffer = vim.api.nvim_get_current_buf() },
        })
      end
    end,
  },
}
