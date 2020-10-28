defmodule LogstashBackend.Transport.Tcp do
  def connect(hostname_or_address, port, opts \\ [])
  def connect(hostname, port, opts) when is_binary(hostname), do: :gen_tcp.connect(to_charlist(hostname), port, opts)
  def connect(address, port, opts), do: :gen_tcp.connect(address, port, opts)

  def send(socket, msg) when is_binary(msg), do: :gen_tcp.send(socket, to_charlist(msg))
  def send(socket, msg), do: :gen_tcp.send(socket, msg)
end
