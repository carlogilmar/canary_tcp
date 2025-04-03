defmodule Chat.Acceptor do
  use GenServer

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

    # Dynamic Supervisor
    {:ok, sup} = DynamicSupervisor.start_link(max_children: 20)

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


end
