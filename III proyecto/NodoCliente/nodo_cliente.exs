defmodule NodoCliente do

  @moduledoc """
  Módulo responsable de manejar toda la lógica del cliente remoto dentro del
  sistema distribuido de la Hackathon Code4Future. Este módulo representa al cliente, quien interactúa con el servidor enviando
  mensajes y recibiendo respuestas mediante comunicación entre nodos distribuidos.
  """
  @nombre_servicio_local :servicio_cliente
  @servicio_local {@nombre_servicio_local, :nodocliente@cliente}
  @nodo_remoto :"nodoservidor@localhost"
  @servicio_remoto {:servicio_hackathon, @nodo_remoto}

  @doc """
  Punto de entrada del cliente. Registra el proceso actual como servicio local e intenta conectarse al nodo remoto. Si la conexión es exitosa, inicia el sistema de menús del cliente.
  """
  def main() do
    Util.mostrar_mensaje("HACKATHON CODE4FUTURE - CLIENTE")
    registrar_servicio(@nombre_servicio_local)

    case establecer_conexion(@nodo_remoto) do
      true -> iniciar_sistema()
      false -> Util.mostrar_error("No se pudo conectar con el servidor")
    end
  end

  @doc """
  Registra el proceso actual bajo un nombre local para que el servidor pueda enviar respuestas mediante "send/2".
  """
  defp registrar_servicio(nombre_servicio_local) do
    Process.register(self(), nombre_servicio_local)
  end

  @doc """
  Intenta establecer conexión con el nodo remoto.
  """
  defp establecer_conexion(nodo_remoto) do
    Node.connect(nodo_remoto)
  end


  defp iniciar_sistema() do
    Util.mostrar_mensaje("=== SISTEMA DE GESTIÓN HACKATHON ===")
    mostrar_menu_inicial()
  end

  @doc """
  Muestra el menú inicial con las opciones:
  1. Iniciar sesión
  2. Registrarse
  3. Salir
  Procesa la opción ingresada e invoca la acción correspondiente.
  """

  defp mostrar_menu_inicial() do
    IO.puts("""

    1. Iniciar sesión
    2. Registrarse
    3. Salir
    """)

    opcion = Util.ingresar("Seleccione una opción:", :texto)
    |> String.trim()

    case opcion do
      "1" -> proceso_login()
      "2" -> proceso_registro()
      "3" ->
        send(@servicio_remoto, {@servicio_local, :fin})
        Util.mostrar_mensaje("Hasta pronto!")
      _ ->
        Util.mostrar_error("Opción inválida")
        mostrar_menu_inicial()
    end
  end

  @doc """
  Solicita email y password al usuario y envía solicitud de login al servidor.
  """
  defp proceso_login() do
    email = Util.ingresar("Email:", :texto) |> String.trim()
    password = Util.ingresar("Password:", :texto) |> String.trim()

    send(@servicio_remoto, {@servicio_local, {:login, email, password}})

    receive do
      {:ok, usuario} ->
        Util.mostrar_exito("¡Bienvenido #{usuario.nombre}!")
        loop_principal(usuario)
      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
        mostrar_menu_inicial()
    after
      5000 ->
        Util.mostrar_error("Timeout en login")
        mostrar_menu_inicial()
    end
  end

  @doc """
  Realiza el proceso de registro de usuario solicitando: Nombre completo, email, password, tipo de usuario (participante o mentor).
  Envía la estructura al servidor y procesa la respuesta.
  """
  defp proceso_registro() do
    nombre = Util.ingresar("Nombre completo:", :texto) |> String.trim()
    email = Util.ingresar("Email:", :texto) |> String.trim()
    password = Util.ingresar("Password:", :texto) |> String.trim()

    IO.puts("""
    Tipo de usuario:
    1. Participante
    2. Mentor
    """)
    tipo_opcion = Util.ingresar("Seleccione:", :texto) |> String.trim()

    tipo = case tipo_opcion do
      "1" -> :participante
      "2" -> :mentor
      _ -> :participante
    end

    send(@servicio_remoto, {@servicio_local, {:registro, nombre, email, password, tipo}})

    receive do
      {:ok, mensaje, _usuario} ->
        Util.mostrar_exito(mensaje)
        mostrar_menu_inicial()
      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
        mostrar_menu_inicial()
    after
      5000 ->
        Util.mostrar_error("Timeout en registro")
        mostrar_menu_inicial()
    end
  end

  @doc """
  Funciona como el bucle principal del cliente después de iniciar sesión.
  """
  defp loop_principal(usuario) do
    mostrar_menu_principal(usuario)

    comando = Util.ingresar("\nComando:", :texto)
    |> String.trim()
    |> String.downcase()

    procesar_comando(comando, usuario)
  end

  @doc """
  Muestra todos los comandos disponibles dependiendo del tipo de usuario (participante o mentor).
  """

  defp mostrar_menu_principal(usuario) do
    no_leidas = obtener_notificaciones_pendientes(usuario.id)
    notif_texto = if no_leidas > 0, do: " 🔔 (#{no_leidas})", else: ""

    menu_mentor = if usuario.tipo == :mentor do
      """
      === COMANDOS DE MENTOR ===
      /feedback       - Dar feedback a proyecto
      /mis_feedback   - Ver mis feedbacks dados
      """
    else
      ""
    end

    IO.puts("""

    ========================================
    Usuario: #{usuario.nombre} [#{usuario.tipo}]#{notif_texto}
    Equipo: #{usuario.equipo_id || "Sin equipo"}
    ========================================

    COMANDOS DISPONIBLES:
    /teams          - Listar equipos
    /create_team    - Crear equipo
    /join           - Unirse a equipo
    /leave          - Salir del equipo
    /project        - Ver proyecto de equipo
    /register_proj  - Registrar proyecto
    /update_proj    - Actualizar avance
    /chat           - Entrar al chat en tiempo real
    /messages       - Ver historial de mensajes
    /notif          - Ver notificaciones
    /mentors       - Listar mentores disponibles
    /request      - Solicitar ayuda de mentor
    #{menu_mentor}/help           - Mostrar ayuda
    /logout         - Cerrar sesión
    """)
  end


  @doc """
  Solicita al servidor el número de notificaciones no leídas del usuario. Si hay timeout, devuelve 0.
  """
  defp obtener_notificaciones_pendientes(usuario_id) do
    send(@servicio_remoto, {@servicio_local, {:contar_no_leidas, usuario_id}})

    receive do
      {:ok, cantidad} -> cantidad
    after
      2000 -> 0
    end
  end


  @doc """
  Comando que cierra la sesión del usuario. Desconecta al usuario del nodo.
  """
  defp procesar_comando("/logout", _usuario) do
    Util.mostrar_mensaje("Sesión cerrada")
    mostrar_menu_inicial()
  end

  @doc """
  Comando muestra un listado de comandos disponibles. Regresa al loop principal.
  """
  defp procesar_comando("/help", usuario) do
    Util.mostrar_mensaje("Ayuda del sistema mostrada")
    loop_principal(usuario)
  end

  @doc """
  Comando solicita al servidor que envíe la lista de equipos existentes.
  """
  defp procesar_comando("/teams", usuario) do
    send(@servicio_remoto, {@servicio_local, :listar_equipos})
    recibir_y_mostrar_respuesta()
    loop_principal(usuario)
  end

  @doc """
  Comando crea un equipo nuevo.
  """
  defp procesar_comando("/create_team", usuario) do
    if usuario.equipo_id != nil do
      Util.mostrar_error("Ya perteneces a un equipo")
    else
      nombre = Util.ingresar("Nombre del equipo:", :texto) |> String.trim()
      tema = Util.ingresar("Tema del equipo:", :texto) |> String.trim()

      send(@servicio_remoto, {@servicio_local, {:crear_equipo, nombre, tema, usuario.id}})

      receive do
        {:ok, mensaje, equipo} ->
          Util.mostrar_exito(mensaje)
          # Actualizar usuario local
          usuario_actualizado = %{usuario | equipo_id: equipo.id}
          loop_principal(usuario_actualizado)
        {:error, mensaje} ->
          Util.mostrar_error(mensaje)
          loop_principal(usuario)
      after
        5000 ->
          Util.mostrar_error("Timeout")
          loop_principal(usuario)
      end
    end
  end

  @doc """
  Comando que permite salir de un equipo.
  """
  defp procesar_comando("/leave", usuario) do
    if usuario.equipo_id == nil do
      Util.mostrar_error("No perteneces a ningún equipo")
      loop_principal(usuario)
    else
      IO.puts("¿Estás seguro que quieres salir del equipo? (si/no)")
      confirmacion = Util.ingresar("Confirmar:", :texto) |> String.trim() |> String.downcase()

      if confirmacion == "si" do
        send(@servicio_remoto, {@servicio_local, {:salir_equipo, usuario.equipo_id, usuario.id}})

        receive do
          {:ok, mensaje} ->
            Util.mostrar_exito(mensaje)
            usuario_actualizado = %{usuario | equipo_id: nil}
            loop_principal(usuario_actualizado)
          {:error, mensaje} ->
            Util.mostrar_error(mensaje)
            loop_principal(usuario)
        after
          5000 ->
            Util.mostrar_error("Timeout")
            loop_principal(usuario)
        end
      else
        Util.mostrar_mensaje("Cancelado")
        loop_principal(usuario)
      end
    end
  end

  @doc """
  Comando que permite unirse a un grupo existente.
  """
  defp procesar_comando("/join", usuario) do
    if usuario.equipo_id != nil do
      Util.mostrar_error("Ya perteneces a un equipo")
      loop_principal(usuario)
    else
      equipo_id = Util.ingresar("ID del equipo:", :texto) |> String.trim()

      send(@servicio_remoto, {@servicio_local, {:unirse_equipo, equipo_id, usuario.id}})

      receive do
        {:ok, mensaje} ->
          Util.mostrar_exito(mensaje)
          usuario_actualizado = %{usuario | equipo_id: equipo_id}
          loop_principal(usuario_actualizado)
        {:error, mensaje} ->
          Util.mostrar_error(mensaje)
          loop_principal(usuario)
      after
        5000 ->
          Util.mostrar_error("Timeout")
          loop_principal(usuario)
      end
    end
  end

  @doc """
  Comando que registra un proyecto del equipo.
  """
  defp procesar_comando("/register_proj", usuario) do
    if usuario.equipo_id == nil do
      Util.mostrar_error("Debes pertenecer a un equipo primero")
      loop_principal(usuario)
    else
      nombre = Util.ingresar("Nombre del proyecto:", :texto) |> String.trim()
      descripcion = Util.ingresar("Descripción:", :texto) |> String.trim()

      IO.puts("Categoría: social / ambiental / educativo")
      categoria = Util.ingresar("Categoría:", :texto) |> String.trim()

      send(@servicio_remoto, {@servicio_local, {:registrar_proyecto, usuario.equipo_id, nombre, descripcion, categoria}})
      recibir_y_mostrar_respuesta()
      loop_principal(usuario)
    end
  end

  @doc """
  Comando que registrar avances del proyecto.
  """
  defp procesar_comando("/update_proj", usuario) do
    if usuario.equipo_id == nil do
      Util.mostrar_error("Debes pertenecer a un equipo primero")
      loop_principal(usuario)
    else
      proyecto_id = Util.ingresar("ID del proyecto:", :texto) |> String.trim()
      avance = Util.ingresar("Descripción del avance:", :texto) |> String.trim()

      send(@servicio_remoto, {@servicio_local, {:actualizar_proyecto, proyecto_id, avance}})
      recibir_y_mostrar_respuesta()
      loop_principal(usuario)
    end
  end

  @doc """
  Comando que permite ver la información de un proyecto.
  """
  defp procesar_comando("/project", usuario) do
    if usuario.equipo_id == nil do
      Util.mostrar_error("Debes pertenecer a un equipo primero")
    else
      proyecto_id = Util.ingresar("ID del proyecto:", :texto) |> String.trim()
      send(@servicio_remoto, {@servicio_local, {:info_proyecto, proyecto_id}})
      recibir_y_mostrar_respuesta()
    end
    loop_principal(usuario)
  end

  @doc """
  Comando que permite entrar al chat en tiempo real del equipo.
  """
  defp procesar_comando("/chat", usuario) do
    if usuario.equipo_id == nil do
      Util.mostrar_error("Debes pertenecer a un equipo primero")
      loop_principal(usuario)
    else
      # Iniciar modo chat en tiempo real
      iniciar_modo_chat(usuario)
    end
  end

  @doc """
  Inicia el modo chat para un equipo.
  """

  defp iniciar_modo_chat(usuario) do
    Util.mostrar_mensaje("=== MODO CHAT EN TIEMPO REAL ===")
    Util.mostrar_mensaje("Escribe 'salir' para volver al menú principal")
    Util.mostrar_mensaje("Escribe '/online' para ver usuarios conectados")

    # Suscribirse al chat del equipo
    send(@servicio_remoto, {@servicio_local, {:suscribir_chat, usuario.equipo_id, self()}})

    receive do
      {:ok, mensaje} ->
        Util.mostrar_exito(mensaje)
        # Iniciar listener de mensajes en segundo plano
        listener_pid = spawn(fn -> escuchar_mensajes_chat() end)
        loop_chat(usuario, listener_pid)
      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
        loop_principal(usuario)
    after
      5000 ->
        Util.mostrar_error("Timeout al suscribirse")
        loop_principal(usuario)
    end
  end

  @doc """
  Loop interactivo del chat.
  """

  defp loop_chat(usuario, listener_pid) do
    texto = IO.gets("\n[#{usuario.nombre}]: ")
    |> String.trim()

    cond do
      texto == "salir" ->
        # Desuscribirse del chat
        send(@servicio_remoto, {@servicio_local, {:desuscribir_chat, usuario.equipo_id, self()}})
        Process.exit(listener_pid, :normal)
        receive do
          {:ok, _} -> :ok
        after
          1000 -> :ok
        end
        Util.mostrar_mensaje("Has salido del chat")
        loop_principal(usuario)

      texto == "/online" ->
        send(@servicio_remoto, {@servicio_local, {:cantidad_suscritos, usuario.equipo_id}})
        receive do
          {:ok, cantidad} ->
            Util.mostrar_mensaje("Usuarios conectados: #{cantidad}")
        after
          2000 -> Util.mostrar_error("Timeout")
        end
        loop_chat(usuario, listener_pid)

      String.length(texto) > 0 ->
        # Enviar mensaje con broadcast
        send(@servicio_remoto, {@servicio_local, {:enviar_mensaje_broadcast, usuario.equipo_id, usuario.id, texto, :chat}})
        receive do
          {:ok, _, _} -> :ok
          {:error, msg} -> Util.mostrar_error(msg)
        after
          2000 -> :ok
        end
        loop_chat(usuario, listener_pid)

      true ->
        loop_chat(usuario, listener_pid)
    end
  end


  @doc """
  Escucha permanentemente mensajes de tipo "{:nuevo_mensaje, mensaje}".
  """
  defp escuchar_mensajes_chat() do
    receive do
      {:nuevo_mensaje, mensaje} ->
        mostrar_mensaje_chat(mensaje)
        escuchar_mensajes_chat()
    end
  end

  @doc """
  Imprime un mensaje formateado en el chat. Recupera el nombre del usuario.
  """
  defp mostrar_mensaje_chat(mensaje) do
    # Obtener nombre del usuario
    usuario_nombre = obtener_nombre_usuario_cache(mensaje.usuario_id)
    timestamp = String.slice(mensaje.timestamp, 11..18)
    IO.puts("\n[#{timestamp}] #{usuario_nombre}: #{mensaje.contenido}")
  end

  @doc """
  Devuelve el nombre del usuario según su ID.
  """
  defp obtener_nombre_usuario_cache(usuario_id) do
    # Por simplicidad, mostramos el ID.
    # En una versión más completa, mantendríamos un caché de nombres
    usuario_id
  end

  @doc """
  Comando que permite ver mensajes históricos.
  """

  defp procesar_comando("/messages", usuario) do
    if usuario.equipo_id == nil do
      Util.mostrar_error("Debes pertenecer a un equipo primero")
    else
      send(@servicio_remoto, {@servicio_local, {:obtener_mensajes, usuario.equipo_id}})
      recibir_y_mostrar_respuesta()
    end
    loop_principal(usuario)
  end

  @doc """
  Comando que permite ver notificaciones.
  """

  defp procesar_comando("/notif", usuario) do
    send(@servicio_remoto, {@servicio_local, {:obtener_notificaciones, usuario.id}})

    receive do
      {:ok, notificaciones} ->
        if is_list(notificaciones) and length(notificaciones) > 0 do
          IO.puts("\n=== NOTIFICACIONES ===")
          Enum.each(notificaciones, fn n ->
            leida_emoji = if n.leida, do: "✓", else: "●"
            IO.puts("#{leida_emoji} [#{n.tipo}] #{n.titulo}")
            IO.puts("   #{n.mensaje}")
            IO.puts("   #{n.timestamp}\n")
          end)
        else
          Util.mostrar_mensaje("No tienes notificaciones")
        end
      {:error, msg} -> Util.mostrar_error(msg)
    after
      5000 -> Util.mostrar_error("Timeout")
    end
    loop_principal(usuario)
  end

  @doc """
  Comando que permite ver mentores disponibles.
  """
  defp procesar_comando("/mentors", usuario) do
    send(@servicio_remoto, {@servicio_local, :listar_mentores})
    recibir_y_mostrar_respuesta()
    loop_principal(usuario)
  end

  @doc """
  Comando que permite solicitar mentoria.
  """

  defp procesar_comando("/request", usuario) do
    if usuario.equipo_id == nil do
      Util.mostrar_error("Debes pertenecer a un equipo primero")
    else
      mentor_id = Util.ingresar("ID del mentor:", :texto) |> String.trim()
      consulta = Util.ingresar("Tu consulta:", :texto) |> String.trim()

      send(@servicio_remoto, {@servicio_local, {:solicitar_mentoria, usuario.equipo_id, mentor_id, consulta}})
      recibir_y_mostrar_respuesta()
    end
    loop_principal(usuario)
  end

  @doc """
  Comando que permite registrar feedback, solo para mentores.
  """
  defp procesar_comando("/feedback", usuario) do
    if usuario.tipo != :mentor do
      Util.mostrar_error("Solo los mentores pueden dar feedback")
    else
      proyecto_id = Util.ingresar("ID del proyecto:", :texto) |> String.trim()
      contenido = Util.ingresar("Tu feedback:", :texto) |> String.trim()

      send(@servicio_remoto, {@servicio_local, {:registrar_feedback, proyecto_id, usuario.id, contenido}})
      recibir_y_mostrar_respuesta()
    end
    loop_principal(usuario)
  end

  @doc """
  Comando que permite ver feedback dado por un mentor.
  """
  defp procesar_comando("/mis_feedback", usuario) do
    if usuario.tipo != :mentor do
      Util.mostrar_error("Solo los mentores pueden ver esta opción")
    else
      send(@servicio_remoto, {@servicio_local, {:feedback_mentor, usuario.id}})
      recibir_y_mostrar_respuesta()
    end
    loop_principal(usuario)
  end

  defp procesar_comando(_comando, usuario) do
    Util.mostrar_error("Comando no reconocido. Usa /help para ver comandos")
    loop_principal(usuario)
  end

  @doc """
  Función auxiliar para recibir y mostrar respuestas del servidor.
  """

  defp recibir_y_mostrar_respuesta() do
    receive do
      {:ok, datos} ->
        IO.puts("\n✓ Respuesta:")
        IO.inspect(datos, pretty: true, limit: :infinity)
      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
      respuesta ->
        IO.puts("\nRespuesta: #{inspect(respuesta)}")
    after
      5000 ->
        Util.mostrar_error("Timeout al recibir respuesta")
    end
  end
end

NodoCliente.main()
