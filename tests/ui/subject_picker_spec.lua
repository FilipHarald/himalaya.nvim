local subject_picker = require("himalaya.ui.subject_picker")

describe("Subject Picker", function()
	after_each(function()
		package.loaded["fzf-lua"] = nil
	end)

	it("builds a mailbox-scoped message preview command", function()
		local command = subject_picker.preview_command({
			mailbox = "Sent Mail",
			account = "work",
		})

		assert.contains(command, "--account")
		assert.contains(command, "work")
		assert.contains(command, "message")
		assert.contains(command, "read")
		assert.contains(command, "Sent Mail")
		assert.contains(command, "{1}")
	end)

	it("opens the selected envelope from fzf", function()
		local captured_entries
		local captured_opts
		package.loaded["fzf-lua"] = {
			fzf_exec = function(entries, opts)
				captured_entries = entries
				captured_opts = opts
			end,
		}

		local envelopes = {
			{
				id = "42",
				subject = "Quarterly\tReport",
				from = { { name = "Alice" } },
				date = "2026-10-02",
			},
		}
		local selected
		subject_picker.open(envelopes, { mailbox = "Inbox" }, function(envelope)
			selected = envelope
		end)

		assert.equals(1, #captured_entries)
		assert.contains(captured_entries[1], "Quarterly Report")
		assert.contains(captured_opts.preview, "message")
		captured_opts.actions.enter(captured_entries)
		assert.equals(envelopes[1], selected)
	end)
end)
