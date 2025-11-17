defmodule SupervisorHackathon do

  @moduledoc """
  Módulo que define la jerarquía de supervisión que mantiene activos los componentes fundamentales del sistema. Supervisor principal del sistema Hackathon.
  """
  use Supervisor

  @doc """
  Función que inicia el supervisor raíz del sistema Hackathon.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Función que inicializa el árbol de procesos supervisados.
  """
  @impl true
  def init(:ok) do
    children = [
      # Supervisor para el sistema de chat
      {Task.Supervisor, name: ChatTaskSupervisor},

      # Worker para el chat concurrente
      %{
        id: ChatConcurrente,
        start: {ChatConcurrente, :start_link, [[]]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      },

      # Worker para verificación periódica de salud
      %{
        id: HealthChecker,
        start: {HealthChecker, :start_link, [[]]},
        restart: :permanent,
        type: :worker
      }
    ]

    # Estrategia: one_for_one - si un proceso falla, solo ese se reinicia
    Supervisor.init(children, strategy: :one_for_one)
  end
end


defmodule HealthChecker do

  @moduledoc """
  Proceso encargado de monitorear periódicamente la salud del sistema.
  """

  use GenServer

  @doc """
  Función que inicia el proceso `HealthChecker` como un `GenServer`.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__] ++ opts)
  end

  @doc """
  Función que inicializa el estado del `HealthChecker` y programa la primera verificación de sistema.
  """
  @impl true
  def init(state) do
    # Verificar salud cada 30 segundos
    schedule_health_check()
    {:ok, state}
  end

  @doc """
  Función que maneja el mensaje `:check_health`, que indica que es momento de verificar el estado del sistema.
  """
  @impl true
  def handle_info(:check_health, state) do
    verificar_sistema()
    schedule_health_check()
    {:noreply, state}
  end

  @doc """
  Función que programa la próxima verificación de salud dentro de 30 segundos.
  """
  defp schedule_health_check() do
    Process.send_after(self(), :check_health, 30_000)
  end

  @doc """
  Función que verifica el estado del proceso `:chat_manager`.
  """
  defp verificar_sistema() do
    # Verificar que el chat_manager esté vivo
    case Process.whereis(:chat_manager) do
      nil ->
        IO.puts("[ERROR] Chat manager no encontrado - reiniciando...")
        ChatConcurrente.start_link([])

      pid ->
        if Process.alive?(pid) do
          :ok
        else
          IO.puts("[ERROR] Chat manager muerto - reiniciando...")
          ChatConcurrente.start_link([])
        end
    end
  end
end
