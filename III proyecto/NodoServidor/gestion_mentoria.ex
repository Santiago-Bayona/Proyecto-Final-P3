defmodule GestionMentoria do

  @moduledoc """
  Módulo encargado de manejar todo lo relacionado con el sistema de mentorías,
  incluyendo registro de feedback, consultas a mentores y validación de roles.
  """

  @doc """
  Función que registra un feedback realizado por un mentor hacia un proyecto.
  """

  def registrar_feedback(proyecto_id, mentor_id, contenido) do
    feedback_list = Persistencia.leer_feedback()

    case validar_mentor(mentor_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, mentor} ->
        nuevo_feedback = crear_feedback(proyecto_id, mentor_id, contenido)
        guardar_feedback(feedback_list, nuevo_feedback)

        # Notificar al equipo sobre el nuevo feedback
        case GestionProyectos.obtener_info(proyecto_id) do
          {:ok, proyecto} ->
            GestionNotificaciones.notificar_equipo(
              proyecto.equipo_id,
              "Nuevo Feedback de Mentor",
              "#{mentor.nombre} ha dejado feedback en tu proyecto",
              :feedback
            )
          _ -> :ok
        end

        {:ok, "Feedback registrado exitosamente", nuevo_feedback}
    end
  end

  @doc """
  Función que obtiene todos los feedback asociados a un proyecto específico.
  """

  def obtener_feedback_proyecto(proyecto_id) do
    feedback_list = Persistencia.leer_feedback()

    feedback_filtrado = Enum.filter(feedback_list, fn f ->
      f.proyecto_id == proyecto_id
    end)

    {:ok, feedback_filtrado}
  end

  @doc """
  Función que obtiene todos los feedback realizados por un mentor específico.
  """
  def obtener_feedback_mentor(mentor_id) do
    feedback_list = Persistencia.leer_feedback()

    feedback_filtrado = Enum.filter(feedback_list, fn f ->
      f.mentor_id == mentor_id
    end)

    {:ok, feedback_filtrado}
  end

  @doc """
  Función que lista todos los feedback registrados en el sistema.
  """
  def listar_feedback() do
    feedback_list = Persistencia.leer_feedback()

    if Enum.empty?(feedback_list) do
      {:ok, "No hay feedback registrado"}
    else
      {:ok, feedback_list}
    end
  end

  @doc """
  Función que permite a un equipo solicitar una mentoría a un mentor.
  """

  def solicitar_mentoria(equipo_id, mentor_id, consulta) do
    case validar_mentor(mentor_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, mentor} ->
        # Notificar al mentor
        GestionNotificaciones.notificar_usuario(
          mentor_id,
          "Solicitud de Mentoría",
          "El equipo #{equipo_id} solicita tu ayuda: #{consulta}",
          :solicitud_mentoria
        )

        # Guardar la consulta como mensaje especial
        GestionChat.enviar_mensaje(equipo_id, "sistema",
          "Consulta enviada a mentor #{mentor.nombre}: #{consulta}",
          :mentoria)

        {:ok, "Solicitud enviada al mentor"}
    end
  end

  # Funciones privadas

  @doc """
  Función que verifica si un usuario tiene rol de mentor.
  """
  defp validar_mentor(mentor_id) do
    case GestionUsuarios.obtener_usuario(mentor_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, usuario} ->
        if usuario.tipo == :mentor do
          {:ok, usuario}
        else
          {:error, "El usuario no es un mentor"}
        end
    end
  end

  @doc """
  Función que crea la estructura Feedback con id y timestamp generados automáticamente.
  """

  defp crear_feedback(proyecto_id, mentor_id, contenido) do
    %Feedback{
      id: Util.generar_id("feedback"),
      proyecto_id: proyecto_id,
      mentor_id: mentor_id,
      contenido: contenido,
      timestamp: Util.obtener_timestamp()
    }
  end

  @doc """
   Función que guarda el feedback en Persistencia, añadiéndolo a la lista existente.
  """

  defp guardar_feedback(feedback_list, nuevo_feedback) do
    Persistencia.escribir_feedback(feedback_list ++ [nuevo_feedback])
  end
  
end
