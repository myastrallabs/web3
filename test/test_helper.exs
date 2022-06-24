# for when we need to simulate HTTP-specific stuff like 413 Request Entity Too Large
Mox.defmock(Web3.HTTP.Mox, for: Web3.HTTP)

ExUnit.start()
