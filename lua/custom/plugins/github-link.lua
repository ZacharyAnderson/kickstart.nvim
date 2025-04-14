return {
  -- GitHub link functionality
  {
    'nvim-lua/plenary.nvim',
    lazy = true,
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    lazy = true,
  },
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      spec = {
        { '<leader>g', group = '[G]it' },
      },
    },
  },
  {
    dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins',
    name = 'github-link',
    event = 'VeryLazy',
    config = function()
      -- Function to copy GitHub link to clipboard
      local function copy_github_link()
        -- Save the current working directory
        local original_cwd = vim.fn.getcwd()

        -- Change to the directory of the current file
        local buffer_dir = vim.fn.expand '%:p:h'
        vim.cmd('cd ' .. vim.fn.fnameescape(buffer_dir))

        -- Get the current file path relative to the repo's root
        local file_path = vim.fn.system('git ls-files --full-name ' .. vim.fn.shellescape(vim.fn.expand '%'))
        if vim.v.shell_error ~= 0 then
          vim.notify('Not a git repository or file not tracked', vim.log.levels.ERROR)
          vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
          return
        end
        file_path = vim.fn.trim(file_path)

        -- Get the line number
        local line_number = vim.fn.line '.'

        -- Get the origin URL from git
        local origin_url = vim.fn.system 'git config --get remote.origin.url'
        if vim.v.shell_error ~= 0 then
          vim.notify('Not a git repository or no origin remote', vim.log.levels.ERROR)
          vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
          return
        end

        -- Get the current branch name
        local branch_name = vim.fn.system 'git rev-parse --abbrev-ref HEAD'
        if vim.v.shell_error ~= 0 then
          vim.notify('Could not determine the current branch', vim.log.levels.ERROR)
          vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
          return
        end
        branch_name = vim.fn.trim(branch_name)

        -- Sanitizing the origin URL
        -- Trim newline and other trailing whitespace
        origin_url = vim.fn.trim(origin_url)

        -- Convert SSH URL to HTTPS URL if needed
        if origin_url:match '^git@' then
          origin_url = origin_url:gsub('^git@(.*):(.*)', 'https://%1/%2')
        end

        -- Remove ".git" suffix if present
        origin_url = origin_url:gsub('%.git$', '')

        -- Construct the URL to the specific line in the file
        local github_link = origin_url .. '/blob/' .. branch_name .. '/' .. file_path .. '#L' .. line_number

        -- Copy the GitHub link to the system clipboard
        vim.fn.setreg('+', github_link)
        vim.notify('Copied to clipboard: ' .. github_link, vim.log.levels.INFO)

        -- Restore the original working directory
        vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
      end

      -- Create a command to call the function
      vim.api.nvim_create_user_command('CopyGithubLinkToClipboard', copy_github_link, {})

      -- Set up keymapping
      vim.keymap.set('n', '<leader>gh', copy_github_link, { desc = 'Copy [G]it[H]ub link to clipboard' })
    end,
  },
}
