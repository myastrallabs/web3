iex: 
	iex --erl "-kernel shell_history enabled" -S mix
format:
	mix do format, surface.format
server:
	iex --erl "-kernel shell_history enabled" -S mix phx.server