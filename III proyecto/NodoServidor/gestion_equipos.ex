defmodule GestionEquipos do

  @moduledoc """
  Módulo encargado de la gestión de equipos en la hackathon.
  """

  @doc """
  Función que devuelve la lista de equipos registrados.
  """
  def listar() do
    equipos = Persistencia.leer_equipos()

    if Enum.empty?(equipos) do
      {:ok, "No hay equipos registrados"}
    else
      {:ok, equipos}
    end
  end

  @doc """
  Función que crea un nuevo equipo con "nombre", "tema" y "creador_id", valida que no exista otro equipo con el mismo nombre.
  """

  def crear(nombre, tema, creador_id) do
    equipos = Persistencia.leer_equipos()

    if nombre_existe?(equipos, nombre) do
      {:error, "Ya existe un equipo con ese nombre"}
    else
      nuevo_equipo = crear_equipo(nombre, tema, creador_id)
      guardar_equipo(equipos, nuevo_equipo)
      actualizar_usuario_con_equipo(creador_id, nuevo_equipo.id)
      {:ok, "Equipo creado exitosamente", nuevo_equipo}
    end
  end

  @doc """
  Función que permite a un usuario unirse al equipo identificado por "equipo_id". Validando que el equipo exista, que el usuario no sea miembro y actualizando la persistencia al agregarse correctamente.
  """

  def unirse(equipo_id, usuario_id) do
    equipos = Persistencia.leer_equipos()

    case Enum.find(equipos, fn e -> e.id == equipo_id end) do
      nil ->
        {:error, "Equipo no encontrado"}

      equipo ->
        if es_miembro?(equipo, usuario_id) do
          {:error, "Ya eres miembro de este equipo"}
        else
          agregar_miembro(equipos, equipo_id, usuario_id)
          actualizar_usuario_con_equipo(usuario_id, equipo_id)
          {:ok, "Te has unido al equipo exitosamente"}
        end
    end
  end

  @doc """
  Función que devuelve la información completa del equipo identificado por "equipo_id".
  """

  def obtener_info(equipo_id) do
    equipos = Persistencia.leer_equipos()

    case Enum.find(equipos, fn e -> e.id == equipo_id end) do
      nil -> {:error, "Equipo no encontrado"}
      equipo -> {:ok, equipo}
    end
  end

  @doc """
   Función que actualiza el campo "proyecto_id" del equipo indicado.
  """

  def actualizar_proyecto(equipo_id, proyecto_id) do
    equipos = Persistencia.leer_equipos()

    equipos_actualizados = Enum.map(equipos, fn e ->
      if e.id == equipo_id do
        %{e | proyecto_id: proyecto_id}
      else
        e
      end
    end)

    Persistencia.escribir_equipos(equipos_actualizados)
    {:ok, "Equipo actualizado con proyecto"}
  end

  @doc """
  Función que retorna la lista de miembros del equipo indicado "id".
  """

  def obtener_miembros(equipo_id) do
    case obtener_info(equipo_id) do
      {:ok, equipo} -> {:ok, equipo.miembros}
      error -> error
    end
  end

  # Funciones Privadas

  @doc """
  Función que verifica si ya existe un equipo con el mismo nombre.
  """
  defp nombre_existe?(equipos, nombre) do
    Enum.any?(equipos, fn e -> e.nombre == nombre end)
  end

  @doc """
  Función que verifica si un usuario ya es miembro del equipo.
  """
  defp es_miembro?(equipo, usuario_id) do
    Enum.member?(equipo.miembros, usuario_id)
  end

  @doc """
  Función que construye la estructura %Equipo{} con los valores iniciales.
  """
  defp crear_equipo(nombre, tema, creador_id) do
    %Equipo{
      id: Util.generar_id("team"),
      nombre: nombre,
      tema: tema,
      miembros: [creador_id],
      proyecto_id: nil,
      activo: true
    }
  end

  @doc """
  Función que persiste la lista de equipos añadiendo el nuevo equipo al final.
  """

  defp guardar_equipo(equipos, nuevo_equipo) do
    Persistencia.escribir_equipos(equipos ++ [nuevo_equipo])
  end

  @doc """
  Función que agrega un nuevo miembro al equipo (actualizando el CSV completo).
  """
  defp agregar_miembro(equipos, equipo_id, usuario_id) do
    equipos_actualizados = Enum.map(equipos, fn e ->
      if e.id == equipo_id do
        %{e | miembros: e.miembros ++ [usuario_id]}
      else
        e
      end
    end)

    Persistencia.escribir_equipos(equipos_actualizados)
  end

  @doc """
  Función que permite a un usuario salir del equipo identificado por "equipo_id". Valida que el equipo exista, que el usuario sea miembro y actualiza la persistencia al salir correctamente.
  """
  def salir_equipo(equipo_id, usuario_id) do
    equipos = Persistencia.leer_equipos()

    case Enum.find(equipos, fn e -> e.id == equipo_id end) do
      nil ->
        {:error, "Equipo no encontrado"}

      equipo ->
        if not es_miembro?(equipo, usuario_id) do
          {:error, "No eres miembro de este equipo"}
        else

          equipos_actualizados = Enum.map(equipos, fn e ->
            if e.id == equipo_id do
              nuevos_miembros = List.delete(e.miembros, usuario_id)
              %{e | miembros: nuevos_miembros}
            else
              e
            end
          end)

          Persistencia.escribir_equipos(equipos_actualizados)

        
          GestionUsuarios.actualizar_equipo_usuario(usuario_id, nil)

          {:ok, "Has salido del equipo exitosamente"}
        end
    end
  end

  @doc """
  Función que llama a GestionUsuarios para actualizar el registro del usuario con su equipo.
  """
  defp actualizar_usuario_con_equipo(usuario_id, equipo_id) do
    GestionUsuarios.actualizar_equipo_usuario(usuario_id, equipo_id)
  end

end
