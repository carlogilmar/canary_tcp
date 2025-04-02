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
      active: :once,
      exit_on_close: false,
      reuseaddr: true,
      backlog: 25
    ]

    # Step 1: Start the TCP server by listening for connections
    case :gen_tcp.listen(port, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Step 1: TCP Server here in port #{port}")
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
    Logger.info("Step 2: Accept a new incoming connection")

    case :gen_tcp.accept(listen_socket, 2_000) do
      {:ok, socket} ->
        Logger.info("Step 3: New connection is requested. Processing...")

        # Create a new process for handle this connection
        {:ok, pid} = TCPEchoServer.Connection.start_link(socket)
        # Give to that process the control over the connection
        :ok = :gen_tcp.controlling_process(socket, pid)
        # Accept another incoming connection
        send(self(), :accept)

        {:noreply, listen_socket}

      {:error, :timeout} ->
        # Default mode... listening for a new connection
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, reason} ->
        {:stop, reason, listen_socket}
    end
  end
end
