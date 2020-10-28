################################################################################
# Copyright 2015 Marcelo Gornstein <marcelog@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
defmodule LogstashBackend do
  @behaviour :gen_event
  use Timex

  alias LogstashBackend.Transport

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name}) do
    {:ok, :ok, configure(name, opts)}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event({_level, group_leader, {Logger, _, _, _}}, state)
      when node(group_leader) != node() do
    {:ok, state}
  end

  def handle_event(
        {level, _group_leader, {Logger, message, timestamp, metadata}},
        %{level: min_level} = state
      ) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, message, timestamp, metadata, state)
    end

    {:ok, state}
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp log_event(level, msg, timestamp, md, %{
         type: type,
         metadata: metadata,
         socket: socket,
         connection_module: connection_module
       }) do
    fields =
      md
      |> Keyword.merge(metadata)
      |> Keyword.put(:level, to_string(level))
      |> metadata_to_map()

    ts =
      timestamp
      |> maybe_local_timestamp()
      |> maybe_format_timestamp()

    json =
      Jason.encode!(%{
        type: type,
        "@timestamp": ts,
        message: to_string(msg),
        fields: fields
      })

    # :gen_udp.send(socket, host, port, to_charlist(json))
    :ok = connection_module.send(socket, to_charlist(json <> "\n"))
  end

  defp configure(name, opts) do

    # Load / Construct opts from config and runtime options
    opts =
      :logger
      |> Application.get_env(name, [])
      |> Keyword.merge(opts)

    Application.put_env(:logger, name, opts)

    # Get configuration values
    level = Keyword.get(opts, :level, :debug)
    metadata = Keyword.get(opts, :metadata, [])
    type = Keyword.get(opts, :type, "elixir")
    connection_type = Keyword.get(opts, :connection_type, "ssl")
    host = Keyword.get(opts, :host)
    port = Keyword.get(opts, :port)

    tcp_options = Keyword.get(opts, :tcp_options, [])
    ssl_options = Keyword.get(opts, :ssl_options, [])

    {connection_module, options} =
      case connection_type do
        "ssl" ->
          Application.ensure_started(:ssl)
          {Transport.Ssl, ssl_options}
        "tcp" -> {Transport.Tcp, tcp_options}
        _ -> raise "invalid connection_type"
      end

    {:ok, socket} = connection_module.connect(host, port, options)

    Application.ensure_all_started(:timex)
    %{
      name: name,
      host: to_charlist(host),
      port: port,
      level: level,
      socket: socket,
      type: type,
      metadata: metadata,
      connection_module: connection_module
    }
  end

  # Maybe returns the local timestamp, otherwise the given timestamp / data is returned
  defp maybe_local_timestamp({{year, month, day}, {hour, minute, second, milliseconds}} = timestamp) do
    case NaiveDateTime.new(year, month, day, hour, minute, second, milliseconds * 1_000) do
      {:ok, naive_timestamp} ->
        case Timex.to_datetime(naive_timestamp, :local) do
          {:error, _reason} ->
            timestamp

          local_timestamp ->
            local_timestamp
        end

      {:error, _reason} ->
        timestamp
    end
  end

  defp maybe_local_timestamp(timestamp), do: timestamp

  defp maybe_format_timestamp(timestamp) do
    case Timex.format(timestamp, "{ISO:Extended}") do
      {:ok, formatted_timestamp} ->
        formatted_timestamp
      {:error, _reason} ->
        timestamp
    end
  end

  # Converts the given metadata to a map, which is encodable by Jason
  defp metadata_to_map(metadata) do
    fields =
      metadata
      |> Enum.into(%{})
      |> inspect_pids
      |> inspect_functions

    {_, fields} =
      Map.get_and_update(fields, :mfa, fn value ->
        case value do
          nil -> :pop
          val -> {val, inspect(val)}
        end
      end)

    fields
  end

  # inspects the argument only if it is a pid
  defp inspect_pid(pid) when is_pid(pid), do: inspect(pid)
  defp inspect_pid(other), do: other

  # inspects the field values only if they are pids
  defp inspect_pids(fields) when is_map(fields) do
    Enum.into(fields, %{}, fn {key, value} ->
      {key, inspect_pid(value)}
    end)
  end

  defp inspect_function(func) when is_function(func), do: inspect(func)
  defp inspect_function(value), do: value

  defp inspect_functions(fields) when is_map(fields) do
    Enum.into(fields, %{}, fn {key, value} ->
      {key, inspect_function(value)}
    end)
  end
end
