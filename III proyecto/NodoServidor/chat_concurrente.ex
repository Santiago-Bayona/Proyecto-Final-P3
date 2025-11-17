defmodule ChatConcurrente do
  use GenServer

  @moduledoc """
  Módulo encargado de gestionar el sistema de chat concurrente entre equipos utilizando un proceso `GenServer`.
  """

  @doc """
  Inicia el servidor de chat concurrente.
  """
  # API Pública
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts ++ [name: :chat_manager])
  end

  @doc """
  Función que inicia el chat si aún no existe.
  """
  def iniciar() do
    case Process.whereis(:chat_manager) do
      nil -> start_link()
      pid -> {:ok, pid}
    end
  end

  @doc """
  Inicializa el estado del servidor.
  """
  # Callbacks de GenServer
  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @doc """
  Maneja la suscripción de un cliente al chat de un equipo.
  """
  @impl true
  def handle_call({:suscribir, equipo_id, cliente_pid}, _from, suscripciones) do
    nuevas_suscripciones = agregar_suscripcion(suscripciones, equipo_id, cliente_pid)
    {:reply, {:ok, "Suscrito al chat del equipo #{equipo_id}"}, nuevas_suscripciones}
  end

  @doc """
  Maneja la desuscripción del cliente del chat del equipo.
  """
  @impl true
  def handle_call({:desuscribir, equipo_id, cliente_pid}, _from, suscripciones) do
    nuevas_suscripciones = remover_suscripcion(suscripciones, equipo_id, cliente_pid)
    {:reply, {:ok, "Desuscrito del chat"}, nuevas_suscripciones}
  end

  @doc """
   Retorna la cantidad de procesos suscritos al equipo dado.
  """
  @impl true
  def handle_call({:obtener_suscritos, equipo_id}, _from, suscripciones) do
    suscritos = Map.get(suscripciones, equipo_id, [])
    {:reply, {:ok, length(suscritos)}, suscripciones}
  end

  @doc """
  Maneja el broadcast de un mensaje a todos los procesos suscritos.
  """
  @impl true
  def handle_cast({:broadcast, equipo_id, mensaje}, suscripciones) do
    broadcast_mensaje(suscripciones, equipo_id, mensaje)
    {:noreply, suscripciones}
  end

  # Funciones privadas

  @doc """
  Función que agrega una suscripción para un "cliente_pid" al chat del "equipo_id".
  """
  defp agregar_suscripcion(suscripciones, equipo_id, cliente_pid) do
    suscritos_actuales = Map.get(suscripciones, equipo_id, [])

    if Enum.member?(suscritos_actuales, cliente_pid) do
      suscripciones
    else
      Map.put(suscripciones, equipo_id, [cliente_pid | suscritos_actuales])
    end
  end

  @doc """
  Función que remueve una suscripción de "cliente_pid" del chat del "equipo_id".
  """
  defp remover_suscripcion(suscripciones, equipo_id, cliente_pid) do
    suscritos_actuales = Map.get(suscripciones, equipo_id, [])
    nuevos_suscritos = List.delete(suscritos_actuales, cliente_pid)

    if Enum.empty?(nuevos_suscritos) do
      Map.delete(suscripciones, equipo_id)
    else
      Map.put(suscripciones, equipo_id, nuevos_suscritos)
    end
  end

  @doc """
  Función que envía (broadcast) un "mensaje" a todos los procesos suscritos al "equipo_id".
  """
  defp broadcast_mensaje(suscripciones, equipo_id, mensaje) do
    suscritos = Map.get(suscripciones, equipo_id, [])

    # Usar Task.Supervisor para mejor manejo de errores
    tasks = Enum.map(suscritos, fn cliente_pid ->
      Task.Supervisor.async_nolink(ChatTaskSupervisor, fn ->
        enviar_mensaje_a_cliente(cliente_pid, mensaje)
      end)
    end)

    # Esperar resultados con timeout
    Enum.each(tasks, fn task ->
      try do
        Task.await(task, 5000)
      catch
        :exit, _ -> :ok
      end
    end)
  end

  @doc """
  Función que envía el mensaje directamente al "cliente_pid" verificando que el proceso esté vivo.
  """
  defp enviar_mensaje_a_cliente(cliente_pid, mensaje) do
    if Process.alive?(cliente_pid) do
      send(cliente_pid, {:nuevo_mensaje, mensaje})
      :ok
    else
      :proceso_muerto
    end
  end
  
end
