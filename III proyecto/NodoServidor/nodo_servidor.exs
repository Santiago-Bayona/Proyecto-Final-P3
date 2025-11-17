defmodule NodoServidor do

  @moduledoc """
   Módulo principal del servidor del Hackathon.
  """

  @nombre_servicio_local :servicio_hackathon

  @doc """
   Punto de inicio del servidor.
  """

  def main() do
    Util.mostrar_mensaje("SERVIDOR HACKATHON INICIADO")
    inicializar_datos()
    iniciar_supervisor()
    registrar_servicio(@nombre_servicio_local)
    procesar_mensajes()
  end

  @doc """
  Función que crea los archivos CSV del sistema si no existen y registra un usuario.
  """

  defp inicializar_datos() do
    # Crear archivos CSV si no existen con usuario admin predeterminado
    unless File.exists?("usuarios.csv") do
      usuarios_default = [
        %Usuario{
          id: "user_admin",
          nombre: "Admin",
          email: "admin@hackathon.com",
          password: "admin123",
          tipo: :mentor,
          equipo_id: nil
        },
        %Usuario{
          id: "user_mentor1",
          nombre: "Carlos Mentor",
          email: "carlos@hackathon.com",
          password: "mentor123",
          tipo: :mentor,
          equipo_id: nil
        }
      ]
      Persistencia.escribir_usuarios(usuarios_default)
    end

    unless File.exists?("equipos.csv") do
      Persistencia.escribir_equipos([])
    end

    unless File.exists?("proyectos.csv") do
      Persistencia.escribir_proyectos([])
    end

    unless File.exists?("mensajes.csv") do
      Persistencia.escribir_mensajes([])
    end

    unless File.exists?("feedback.csv") do
      Persistencia.escribir_feedback([])
    end

    unless File.exists?("notificaciones.csv") do
      File.write("notificaciones.csv", "id,usuario_id,titulo,mensaje,tipo,timestamp,leida\n")
    end

    Util.mostrar_exito("Datos inicializados correctamente")
  end

  @doc """
   Función que inicia el supervisor encargado de gestionar workers como los procesos de chat.
  """

  defp iniciar_supervisor() do
    {:ok, _pid} = SupervisorHackathon.start_link([])
    Util.mostrar_exito("Supervisor iniciado con tolerancia a fallos")
    # Pequeña espera para que los workers inicien
    Process.sleep(500)
  end

  @doc """
  Función que permite registrar el proceso actual bajo un nombre accesible para nodos remotos.
  """
  defp registrar_servicio(nombre_servicio_local) do
    Process.register(self(), nombre_servicio_local)
  end

  @doc """
  Ciclo recursivo que recibe mensajes, los procesa y envía respuesta al cliente.  Permanece activo hasta recibir ":fin".
  """

  defp procesar_mensajes() do
    receive do
      {productor, mensaje} ->
        respuesta = procesar_mensaje(mensaje)
        send(productor, respuesta)
        if respuesta != :fin, do: procesar_mensajes()
    end
  end

  @doc """
  Mensaje especial para terminar el servidor.
  """

  defp procesar_mensaje(:fin), do: :fin


  # ============ AUTENTICACIÓN ============ Comandos relacionados con el inicio de sesión y registro de usuarios. El servidor únicamente redirige la petición al módulo correspondiente.

  defp procesar_mensaje({:login, email, password}) do
    GestionUsuarios.login(email, password)
  end

  defp procesar_mensaje({:registro, nombre, email, password, tipo}) do
    GestionUsuarios.registrar(nombre, email, password, tipo)
  end

  # ============ GESTIÓN DE USUARIOS ============ Permite consultar la información de usuarios y mentores.
  defp procesar_mensaje(:listar_usuarios) do
    GestionUsuarios.listar_usuarios()
  end

  defp procesar_mensaje(:listar_mentores) do
    GestionUsuarios.listar_mentores()
  end

  defp procesar_mensaje({:obtener_usuario, usuario_id}) do
    GestionUsuarios.obtener_usuario(usuario_id)
  end

  # ============ GESTIÓN DE EQUIPOS ============ Maneja la creación, unión y consultas de equipos registrados.

  defp procesar_mensaje(:listar_equipos) do
    GestionEquipos.listar()
  end

  defp procesar_mensaje({:crear_equipo, nombre, tema, creador_id}) do
    GestionEquipos.crear(nombre, tema, creador_id)
  end

  defp procesar_mensaje({:unirse_equipo, equipo_id, usuario_id}) do
    GestionEquipos.unirse(equipo_id, usuario_id)
  end

  defp procesar_mensaje({:info_equipo, equipo_id}) do
    GestionEquipos.obtener_info(equipo_id)
  end

  defp procesar_mensaje({:miembros_equipo, equipo_id}) do
    GestionEquipos.obtener_miembros(equipo_id)
  end

  defp procesar_mensaje({:salir_equipo, equipo_id, usuario_id}) do
    GestionEquipos.salir_equipo(equipo_id, usuario_id)
  end

  # ============ GESTIÓN DE PROYECTOS ============  Acciones sobre los proyectos creados por los equipos: registro, actualización, filtrado y consultas.

  defp procesar_mensaje({:registrar_proyecto, equipo_id, nombre, descripcion, categoria}) do
    GestionProyectos.registrar(equipo_id, nombre, descripcion, categoria)
  end

  defp procesar_mensaje({:actualizar_proyecto, proyecto_id, nuevo_avance}) do
    GestionProyectos.actualizar_avance(proyecto_id, nuevo_avance)
  end

  defp procesar_mensaje({:actualizar_estado_proyecto, proyecto_id, nuevo_estado}) do
    GestionProyectos.actualizar_estado(proyecto_id, nuevo_estado)
  end

  defp procesar_mensaje({:info_proyecto, proyecto_id}) do
    GestionProyectos.obtener_info(proyecto_id)
  end

  defp procesar_mensaje(:listar_proyectos) do
    GestionProyectos.listar()
  end

  defp procesar_mensaje({:proyectos_categoria, categoria}) do
    GestionProyectos.listar_por_categoria(categoria)
  end

  defp procesar_mensaje({:proyectos_estado, estado}) do
    GestionProyectos.listar_por_estado(estado)
  end

  defp procesar_mensaje({:proyecto_equipo, equipo_id}) do
    GestionProyectos.obtener_por_equipo(equipo_id)
  end

  # ============ GESTIÓN DE CHAT (CONCURRENTE CON GENSERVER) ============ Maneja el sistema de mensajería por equipo y el broadcast. Incluyendo la suscripción/desuscripción de procesos al chat.
  defp procesar_mensaje({:enviar_mensaje, equipo_id, usuario_id, contenido, tipo}) do
    GestionChat.enviar_mensaje(equipo_id, usuario_id, contenido, tipo)
  end

  defp procesar_mensaje({:enviar_mensaje_broadcast, equipo_id, usuario_id, contenido, tipo}) do
    GestionChat.enviar_mensaje_broadcast(equipo_id, usuario_id, contenido, tipo)
  end

  defp procesar_mensaje({:suscribir_chat, equipo_id, cliente_pid}) do
    GestionChat.suscribir_chat(equipo_id, cliente_pid)
  end

  defp procesar_mensaje({:desuscribir_chat, equipo_id, cliente_pid}) do
    GestionChat.desuscribir_chat(equipo_id, cliente_pid)
  end

  defp procesar_mensaje({:cantidad_suscritos, equipo_id}) do
    GestionChat.obtener_cantidad_suscritos(equipo_id)
  end

  defp procesar_mensaje({:obtener_mensajes, equipo_id}) do
    GestionChat.obtener_mensajes_equipo(equipo_id)
  end

  defp procesar_mensaje({:mensajes_tipo, equipo_id, tipo}) do
    GestionChat.obtener_mensajes_tipo(equipo_id, tipo)
  end

  defp procesar_mensaje({:ultimos_mensajes, equipo_id, cantidad}) do
    GestionChat.obtener_ultimos_mensajes(equipo_id, cantidad)
  end

  defp procesar_mensaje({:anuncio_general, usuario_id, contenido}) do
    GestionChat.enviar_anuncio_general(usuario_id, contenido)
  end

  defp procesar_mensaje(:obtener_anuncios) do
    GestionChat.obtener_anuncios_generales()
  end

  # ============ GESTIÓN DE MENTORÍA ============ Registro, consulta y filtrado del feedback dado por mentores.
  defp procesar_mensaje({:registrar_feedback, proyecto_id, mentor_id, contenido}) do
    GestionMentoria.registrar_feedback(proyecto_id, mentor_id, contenido)
  end

  defp procesar_mensaje({:feedback_proyecto, proyecto_id}) do
    GestionMentoria.obtener_feedback_proyecto(proyecto_id)
  end

  defp procesar_mensaje({:feedback_mentor, mentor_id}) do
    GestionMentoria.obtener_feedback_mentor(mentor_id)
  end

  defp procesar_mensaje(:listar_feedback) do
    GestionMentoria.listar_feedback()
  end

  defp procesar_mensaje({:solicitar_mentoria, equipo_id, mentor_id, consulta}) do
    GestionMentoria.solicitar_mentoria(equipo_id, mentor_id, consulta)
  end

  # ============ GESTIÓN DE NOTIFICACIONES ============ Manejo y consulta de notificaciones por usuario.
  defp procesar_mensaje({:obtener_notificaciones, usuario_id}) do
    GestionNotificaciones.obtener_notificaciones_usuario(usuario_id)
  end

  defp procesar_mensaje({:marcar_leida, notificacion_id}) do
    GestionNotificaciones.marcar_como_leida(notificacion_id)
  end

  defp procesar_mensaje({:contar_no_leidas, usuario_id}) do
    GestionNotificaciones.contar_no_leidas(usuario_id)
  end

  # ============ COMANDO DESCONOCIDO ============ Se ejecuta cuando el mensaje recibido no coincide con ningún patrón. Ayudando a depurar solicitudes incorrectas del cliente.
  defp procesar_mensaje(mensaje) do
    {:error, "Comando desconocido: #{inspect(mensaje)}"}
  end
end

NodoServidor.main()
