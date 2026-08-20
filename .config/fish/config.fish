set -gx EDITOR nvim

if status is-interactive
	and isatty stdout
	fastfetch
end

if status is-interactive
	alias ls='lsd'
	alias cat='bat'
	zoxide init fish | source
end

function fish_greeting
	# nothing
end

# opencode
fish_add_path /home/sharpsight/.opencode/bin
