local cmd = vim.api.nvim_command
local M = {}

-- if focus auto signcolumn is set to true then
-- we assume it to be auto in case signcolumn = no
local function get_sign_column()
	local default_signcolumn = 'auto'
	if vim.opt.signcolumn:get() == 'no' then
		return default_signcolumn
	else
		return vim.opt.signcolumn:get()
	end
end

local function nvim_create_augroups(definitions)
	for group_name, definition in pairs(definitions) do
		cmd('augroup ' .. group_name)
		cmd('autocmd!')
		for _, def in ipairs(definition) do
			local command = table.concat(vim.tbl_flatten({ 'autocmd', def }), ' ')
			cmd(command)
		end
		cmd('augroup END')
	end
end

function M.setup(config)
	local autocmds = {}
	if config.autoresize then
		autocmds['focus_resize'] = {
			--Adding WinEnter no longer breaks snap etc support.. using *defer_fn* ensures filetype that is set AFTER
			-- NOTE: Switched to vim.schedule as its more appropriate for the task and no worry about slow processors etc
			--buffer creation is read, instead of getting the blank filetypes, buffertypes when buffer is INITIALLY created
			-- When a buffer is created its filetype and buffertype etc are blank, and focus reads these
			-- By using defer, focus waits for some time, and then attempts to read the filetype and buffertype
			-- This wait time is enough for plugins to properly set their options to the buffer such as filetype
			-- This is an upstream vim issue because there is no way to specify filetype etc when creating a new buffer
			-- You can only create a blank buffer, and then set the variables after it was created
			-- Which means focus will initially read it as blank buffer and resize. This is an issue for many other plugins that read ft too.
			{
				'BufEnter',
				'*',
				'doautocmd WinScrolled | lua require"focus".resize()',
				-- 'lua vim.schedule(function() require"focus".resize(); vim.cmd([[doautocmd WinScrolled]]) end)',
			},
			{ 'WinEnter,BufEnter', 'NvimTree_*', 'lua require"focus".resize()' },
		}
	end

	if config.signcolumn then
		autocmds['focus_signcolumn'] = {
			{ 'BufEnter,WinEnter', '*', 'setlocal signcolumn=' .. get_sign_column() },
			{ 'BufLeave,WinLeave', '*', 'setlocal signcolumn=no' },
		}
	end

	if config.cursorline then
		autocmds['focus_cursorline'] = {
			{ 'BufEnter,WinEnter', '*', 'setlocal cursorline' },
			{ 'BufLeave,WinLeave', '*', 'setlocal nocursorline' },
		}
	end
	-- FIXME: Disable line numbers on startify buffer, add user config?
	if config.number then
		autocmds['number'] = {
			{ 'BufEnter,WinEnter', '*', 'set number' },
			{ 'BufLeave,WinLeave', '*', 'setlocal nonumber' },
		}
	end
	if config.relativenumber then
		if config.absolutenumber_unfocussed then
			autocmds['focus_relativenumber'] = {
				{ 'BufEnter,WinEnter', '*', 'set nonumber relativenumber' },
				{ 'BufLeave,WinLeave', '*', 'setlocal number norelativenumber' },
			}
		else
			autocmds['focus_relativenumber'] = {
				{ 'BufEnter,WinEnter', '*', 'set nonumber relativenumber' },
				{ 'BufLeave,WinLeave', '*', 'setlocal nonumber norelativenumber' },
			}
		end
	end
	if config.hybridnumber then
		if config.absolutenumber_unfocussed then
			autocmds['focus_hybridnumber'] = {
				{ 'BufEnter,WinEnter', '*', 'set number relativenumber' },
				{ 'BufLeave,WinLeave', '*', 'setlocal number norelativenumber' },
			}
		else
			autocmds['focus_hybridnumber'] = {
				{ 'BufEnter,WinEnter', '*', 'set number relativenumber' },
				{ 'BufLeave,WinLeave', '*', 'setlocal nonumber norelativenumber' },
			}
		end
	end

	if config.cursorcolumn then
		autocmds['focus_cursorcolumn'] = {
			{
				'BufEnter,WinEnter',
				'*',
				'setlocal cursorcolumn',
			},
			{
				'BufLeave,WinLeave',
				'*',
				'setlocal nocursorcolumn',
			},
		}
	end

	if config.colorcolumn.enable then
		autocmds['focus_colorcolumn'] = {
			{
				'BufEnter,WinEnter',
				'*',
				'setlocal colorcolumn=' .. config.colorcolumn.width,
			},
			{
				'BufLeave,WinLeave',
				'*',
				'setlocal colorcolumn=0',
			},
		}
	end

	nvim_create_augroups(autocmds)
end

return M
