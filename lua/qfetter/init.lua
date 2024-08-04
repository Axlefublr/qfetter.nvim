local M = {}

---@class QfetterOpts
---@field backwards boolean? Go to the previous quickfix entry, instead of to the next one.
---@field next_buffer boolean? Go to the next quickfix entry *in a different file*, rather than just the next one (that could be in the same file).
---@field notifications boolean? Whether to show notifications for mark, unmark, clear functions.
local default_opts = {
	backwards = false,
	next_buffer = false,
	notifications = true
}

--- Move to another entry in the current quickfix list.
--- If you're on the last entry, rotate to the first one.
--- If you're not on any qf entry, go to the first one.
---@param opts QfetterOpts?
function M.another(opts)
	local backwards = opts and opts.backwards or default_opts.backwards
	local next_buffer = opts and opts.next_buffer or default_opts.next_buffer
	local qflist = vim.fn.getqflist()
	if #qflist == 0 then
		vim.notify('quickfix list is empty')
		return
	end
	if vim.v.count > 0 then
		vim.cmd('silent! cc ' .. vim.v.count)
		vim.notify('qf ' .. vim.v.count)
		return
	end

	local qflist_index = vim.fn.getqflist({ idx = 0 }).idx
	local current_buffer = vim.api.nvim_get_current_buf()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]

	if qflist_index == 1 and (qflist[1].bufnr ~= current_buffer or qflist[1].lnum ~= current_line) then -- If you do have a quickfix list, the first index is automatically selected, meaning that the first time you try to `cnext`, you go to the second quickfix entry, even though you have never actually visited the first one. This is what I mean when I say vim has a bad foundation and is terrible to build upon. We need a modal editor with a better foundation, with no strange behavior like this!
		vim.cmd('silent! cfirst')
		return
	end

	local status = true
	if backwards then
		if next_buffer then
			---@diagnostic disable-next-line: param-type-mismatch
			status, _ = pcall(vim.cmd, 'cpfile')
		else
			---@diagnostic disable-next-line: param-type-mismatch
			status, _ = pcall(vim.cmd, 'cprev')
		end
		---@diagnostic disable-next-line: param-type-mismatch
		if not status then pcall(vim.cmd, 'clast') end
	else
		if next_buffer then
			---@diagnostic disable-next-line: param-type-mismatch
			status, _ = pcall(vim.cmd, 'cnfile')
		else
			---@diagnostic disable-next-line: param-type-mismatch
			status, _ = pcall(vim.cmd, 'cnext')
		end
		---@diagnostic disable-next-line: param-type-mismatch
		if not status then pcall(vim.cmd, 'cfirst') end
	end
end

--- Add the current position to the quickfix list.
function M.mark()
	local buffer = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = cursor[1]
	local column = cursor[2] + 1
	vim.fn.setqflist({ {
		bufnr = buffer,
		lnum = line,
		col = column,
	} }, 'a')
	if default_opts.notifications then vim.notify('add qf entry') end
end

--- Remove the current quickfix entry from the list.
---@param index integer? The index of the qflist entry you want to remove. Pass `nil` if you want to delete the *current* qflist entry.
function M.unmark(index)
	local count_if_passed_else_current = vim.v.count > 0 and vim.v.count or vim.fn.getqflist({ idx = 0 }).idx
	local selected = index or count_if_passed_else_current
	local qflist = vim.fn.getqflist()
	table.remove(qflist, selected)
	vim.fn.setqflist(qflist, 'r')
	if default_opts.notifications then vim.notify('remove qf ' .. selected) end
end

--- Clear the quickfix list.
function M.clear()
	vim.fn.setqflist({}, 'r')
	if default_opts.notifications then vim.notify('qflist cleared') end
end

---@param opts QfetterOpts
function M.setup(opts)
	default_opts = vim.tbl_extend('force', default_opts, opts)
end

return M
