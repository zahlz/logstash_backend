defmodule LogstashBackend.Transport.Ssl do
  def connect(hostname_or_address, port, opts \\ [])
  def connect(hostname, port, opts) when is_binary(hostname), do: :ssl.connect(to_charlist(hostname), port, opts)
  def connect(address, port, opts), do: :ssl.connect(address, port, opts)

  def send(socket, msg) when is_binary(msg), do: :ssl.send(socket, to_charlist(msg))
  def send(socket, msg), do: :ssl.send(socket, msg)
end
