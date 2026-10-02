local cli = require("himalaya.cli")

local M = {}

local function single_line(value)
	return tostring(value or ""):gsub("[%c]", " ")
end

local function sender_name(envelope)
	local from = envelope.from
	if type(from) ~= "table" then
		return "Unknown"
	end

	local sender = from[1] or from
	if type(sender) ~= "table" then
		return single_line(sender)
	end

	return single_line(sender.name or sender.email or sender.addr or "Unknown")
end

local function entry(envelope)
	return table.concat({
		single_line(envelope.id),
		single_line(envelope.subject or "(no subject)"),
		sender_name(envelope),
		single_line(envelope.date),
	}, "\t")
end

function M.preview_command(opts)
	opts = opts or {}
	local cmd = cli.build_cmd({
		"message",
		"read",
		"-m",
		opts.mailbox,
		"{1}",
	}, { account = opts.account })

	local escaped = {}
	for _, arg in ipairs(cmd) do
		if arg == "{1}" then
			table.insert(escaped, arg)
		else
			table.insert(escaped, vim.fn.shellescape(arg))
		end
	end
	return table.concat(escaped, " ")
end

function M.open(envelopes, opts, on_choice)
	local ok, fzf = pcall(require, "fzf-lua")
	if not ok then
		vim.notify("Subject search requires fzf-lua", vim.log.levels.ERROR)
		return
	end

	local entries = {}
	local envelopes_by_id = {}
	for _, envelope in ipairs(envelopes) do
		local id = tostring(envelope.id or "")
		if id ~= "" then
			table.insert(entries, entry(envelope))
			envelopes_by_id[id] = envelope
		end
	end

	fzf.fzf_exec(entries, {
		prompt = "Mail subjects> ",
		preview = M.preview_command(opts),
		fzf_opts = {
			["--delimiter"] = "\t",
			["--with-nth"] = "2..",
			["--nth"] = "1..",
			["--preview-window"] = "right:60%:wrap",
		},
		actions = {
			["enter"] = function(selected)
				local id = selected and selected[1] and selected[1]:match("^([^\t]+)")
				if id and envelopes_by_id[id] then
					on_choice(envelopes_by_id[id])
				end
			end,
		},
	})
end

return M
