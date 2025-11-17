defmodule GestionChat do

  @moduledoc """
  Módulo encargado de gestionar el envío, almacenamiento y consulta de mensajes
  dentro del sistema de chat.
  """

  @doc """
  Función que se encarga de enviar un mensaje a un equipo especifico, usando la persistencia.
  """

  def enviar_mensaje(equipo_id, usuario_id, contenido, tipo) do
    mensajes = Persistencia.leer_mensajes()

    nuevo_mensaje = crear_mensaje(equipo_id, usuario_id, contenido, tipo)
    guardar_mensaje(mensajes, nuevo_mensaje)

    {:ok, "Mensaje enviado", nuevo_mensaje}
  end

  @doc """
  Función que obtiene todos los mensajes asociados a un equipo filtrandolos con su id.
  """

  def obtener_mensajes_equipo(equipo_id) do
    mensajes = Persistencia.leer_mensajes()
    mensajes_equipo = filtrar_por_equipo(mensajes, equipo_id)

    {:ok, mensajes_equipo}
  end

  @doc """
  Función que obtiene mensajes filtrados por id del equipo y por tipo.
  """

  def obtener_mensajes_tipo(equipo_id, tipo) do
    mensajes = Persistencia.leer_mensajes()

    mensajes_filtrados = Enum.filter(mensajes, fn m ->
      m.equipo_id == equipo_id and m.tipo == tipo
    end)

    {:ok, mensajes_filtrados}
  end

  @doc """
  Función que obtiene los últimos mensajes de un equipo.
  """

  def obtener_ultimos_mensajes(equipo_id, cantidad) do
    {:ok, mensajes} = obtener_mensajes_equipo(equipo_id)

    ultimos = mensajes
    |> Enum.take(-cantidad)

    {:ok, ultimos}
  end

  @doc """
  Función que se encarga de envíar un anuncio general a todos los usuarios del equipo "canal general".
  """

  def enviar_anuncio_general(usuario_id, contenido) do
    enviar_mensaje("general", usuario_id, contenido, :anuncio)
  end

  @doc """
  Función que obtiene todos los anuncios generales. Usa el equipo "general".
  """

  def obtener_anuncios_generales() do
    obtener_mensajes_equipo("general")
  end

  @doc """
  Función que suscribe un proceso cliente ("cliente_pid") a los mensajes de un equipo.
  Delega la suscripción al "chat_manager" (GenServer central).
  """

  def suscribir_chat(equipo_id, cliente_pid) do
    GenServer.call(:chat_manager, {:suscribir, equipo_id, cliente_pid}, 5000)
  end

  @doc """
  Elimina la suscripción de un cliente a un equipo de chat.
  """

  def desuscribir_chat(equipo_id, cliente_pid) do
    GenServer.call(:chat_manager, {:desuscribir, equipo_id, cliente_pid}, 5000)
  end

  @doc """
  Función que retorna la cantidad de procesos suscritos a un equipo de chat.
  """

  def obtener_cantidad_suscritos(equipo_id) do
    GenServer.call(:chat_manager, {:obtener_suscritos, equipo_id}, 5000)
  end

  @doc """
  Función que envía un mensaje a través de broadcast a todos los suscritos del equipo.
  """

  def enviar_mensaje_broadcast(equipo_id, usuario_id, contenido, tipo) do
    mensajes = Persistencia.leer_mensajes()

    nuevo_mensaje = crear_mensaje(equipo_id, usuario_id, contenido, tipo)
    guardar_mensaje(mensajes, nuevo_mensaje)

    # Broadcast usando GenServer.cast (asíncrono)
    GenServer.cast(:chat_manager, {:broadcast, equipo_id, nuevo_mensaje})

    {:ok, "Mensaje enviado a todos", nuevo_mensaje}
  end

  # Funciones Privadas

  @doc """
   Función que crea la estructura completa de un mensaje.
  """

  defp crear_mensaje(equipo_id, usuario_id, contenido, tipo) do
    %Mensaje{
      id: Util.generar_id("msg"),
      equipo_id: equipo_id,
      usuario_id: usuario_id,
      contenido: contenido,
      timestamp: Util.obtener_timestamp(),
      tipo: tipo
    }
  end

  @doc """
  Función que guarda el nuevo mensaje en el archivo.
  """

  defp guardar_mensaje(mensajes, nuevo_mensaje) do
    Persistencia.escribir_mensajes(mensajes ++ [nuevo_mensaje])
  end

  @doc """
  Función que filtra todos los mensajes que pertenecen a un equipo.
  """

  defp filtrar_por_equipo(mensajes, equipo_id) do
    Enum.filter(mensajes, fn m -> m.equipo_id == equipo_id end)
  end

end
