defmodule GestionNotificaciones do

  @moduledoc """
  Módulo encargado de manejar el sistema de notificaciones para los usuarios.
  """

  @doc """
  Función que permite enviar una notificación a todos los miembros de un equipo.
  """
  def notificar_equipo(equipo_id, titulo, mensaje, tipo) do
    case GestionEquipos.obtener_miembros(equipo_id) do
      {:ok, miembros} ->
        # Usar Task para notificar concurrentemente a todos los miembros
        tasks = Enum.map(miembros, fn miembro_id ->
          Task.async(fn ->
            crear_notificacion(miembro_id, titulo, mensaje, tipo)
          end)
        end)

        Task.await_many(tasks, 5000)
        {:ok, "Notificaciones enviadas a #{length(miembros)} miembros"}

      error -> error
    end
  end

  @doc """
  Función que permite enviar una notificación a un solo usuario.
  """
  def notificar_usuario(usuario_id, titulo, mensaje, tipo) do
    crear_notificacion(usuario_id, titulo, mensaje, tipo)
    {:ok, "Notificación enviada"}
  end

  @doc """
  Función que obtiene todas las notificaciones de un usuario específico, ordenadas
  de más reciente a más antigua.
  """

  def obtener_notificaciones_usuario(usuario_id) do
    notificaciones = leer_notificaciones()

    notificaciones_usuario = Enum.filter(notificaciones, fn n ->
      n.usuario_id == usuario_id
    end)
    |> Enum.sort_by(& &1.timestamp, :desc)

    {:ok, notificaciones_usuario}
  end

  @doc """
   Función que marca una notificación como leída.
  """

  def marcar_como_leida(notificacion_id) do
    notificaciones = leer_notificaciones()

    notificaciones_actualizadas = Enum.map(notificaciones, fn n ->
      if n.id == notificacion_id do
        %{n | leida: true}
      else
        n
      end
    end)

    escribir_notificaciones(notificaciones_actualizadas)
    {:ok, "Notificación marcada como leída"}
  end

  @doc """
  Función que cuenta cuántas notificaciones no leídas tiene un usuario.
  """

  def contar_no_leidas(usuario_id) do
    {:ok, notificaciones} = obtener_notificaciones_usuario(usuario_id)

    no_leidas = Enum.count(notificaciones, fn n -> not n.leida end)
    {:ok, no_leidas}
  end

  # Funciones Privadas

  @doc """
  Función que crea una nueva notificación y la guarda en el archivo.
  """
  defp crear_notificacion(usuario_id, titulo, mensaje, tipo) do
    notificaciones = leer_notificaciones()

    nueva_notificacion = %{
      id: Util.generar_id("notif"),
      usuario_id: usuario_id,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      timestamp: Util.obtener_timestamp(),
      leida: false
    }

    escribir_notificaciones(notificaciones ++ [nueva_notificacion])
  end

  @doc """
  Función que lee las notificaciones desde el archivo CSV y las transforma en mapas.
  """

  defp leer_notificaciones() do
    case File.read("notificaciones.csv") do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn line ->
          case String.split(line, ",") do
            ["id", "usuario_id", "titulo", "mensaje", "tipo", "timestamp", "leida"] -> nil
            [id, usuario_id, titulo, mensaje, tipo, timestamp, leida] ->
              %{
                id: id,
                usuario_id: usuario_id,
                titulo: String.replace(titulo, "COMMA", ","),
                mensaje: String.replace(mensaje, "COMMA", ","),
                tipo: String.to_atom(tipo),
                timestamp: timestamp,
                leida: String.to_atom(leida)
              }
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)
      {:error, _} -> []
    end
  end

  @doc """
   Función que escribe todas las notificaciones en el archivo CSV.
  """
  
  defp escribir_notificaciones(notificaciones) do
    headers = "id,usuario_id,titulo,mensaje,tipo,timestamp,leida\n"
    contenido = Enum.map(notificaciones, fn n ->
      titulo_limpio = String.replace(n.titulo, ",", "COMMA")
      mensaje_limpio = String.replace(n.mensaje, ",", "COMMA")
      "#{n.id},#{n.usuario_id},#{titulo_limpio},#{mensaje_limpio},#{n.tipo},#{n.timestamp},#{n.leida}\n"
    end)
    |> Enum.join()
    File.write("notificaciones.csv", headers <> contenido)
  end

end
