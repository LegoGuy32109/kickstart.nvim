-- local buf = 30
-- vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'hello', 'world' })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('JoshTest', { clear = true }),
  pattern = '*.txt',
  callback = function()
    print 'Wow you saved a file!'
  end,
})
