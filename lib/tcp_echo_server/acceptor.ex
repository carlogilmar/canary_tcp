defmodule TCPEchoServer.Acceptor do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    port = Keyword.fetch!(opts, :port)

    listen_options = [
      :binary,
      active: true,
      exit_on_close: false,
      reuseaddr: true,
      backlog: 25
    ]

    # Step 1: Start the TCP server by listening for connections
    case :gen_tcp.listen(port, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("========================================")
        Logger.info("TCP Server here in port #{port}")
        # Message passing to this process
        send(self(), :accept)
        {:ok, listen_socket}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  # Step 2: After listen for connections, then accept a new one
  @impl true
  def handle_info(:accept, listen_socket) do
    case :gen_tcp.accept(listen_socket, 2_000) do
      {:ok, socket} ->
        #{:ok, pid} = TCPEchoServer.Connection.start_link(listen_socket)
        #:ok = :gen_tcp.controlling_process(socket, pid)
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, :timeout} ->
        # Error when try to accept a new connection
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, reason} ->
        {:stop, reason, listen_socket}
    end
  end
end
