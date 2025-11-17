defmodule GestionProyectos do

  @moduledoc """
   Módulo encargado de gestionar los proyectos desarrollados por los equipos.
  """

  @doc """
  Función que permite registrar un nuevo proyecto para un equipo.
  """

  def registrar(equipo_id, nombre, descripcion, categoria) do
    proyectos = Persistencia.leer_proyectos()

    case validar_equipo_sin_proyecto(equipo_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, _equipo} ->
        nuevo_proyecto = crear_proyecto(equipo_id, nombre, descripcion, categoria)
        guardar_proyecto(proyectos, nuevo_proyecto)
        vincular_proyecto_a_equipo(equipo_id, nuevo_proyecto.id)
        {:ok, "Proyecto registrado exitosamente", nuevo_proyecto}
    end
  end

  @doc """
   Función que agrega un avance textual al proyecto seleccionado.
  """

  def actualizar_avance(proyecto_id, nuevo_avance) do
    proyectos = Persistencia.leer_proyectos()

    case Enum.find(proyectos, fn p -> p.id == proyecto_id end) do
      nil ->
        {:error, "Proyecto no encontrado"}

      proyecto ->
        agregar_avance(proyectos, proyecto_id, nuevo_avance)
        {:ok, "Avance registrado exitosamente"}
    end
  end

  @doc """
  Función que permite actualizar el estado de un proyecto.
  """
  def actualizar_estado(proyecto_id, nuevo_estado) do
    proyectos = Persistencia.leer_proyectos()

    proyectos_actualizados = Enum.map(proyectos, fn p ->
      if p.id == proyecto_id do
        %{p | estado: String.to_atom(nuevo_estado)}
      else
        p
      end
    end)

    Persistencia.escribir_proyectos(proyectos_actualizados)
    {:ok, "Estado actualizado"}
  end

  @doc """
  Función que obtiene la información completa de un proyecto.
  """

  def obtener_info(proyecto_id) do
    proyectos = Persistencia.leer_proyectos()

    case Enum.find(proyectos, fn p -> p.id == proyecto_id end) do
      nil -> {:error, "Proyecto no encontrado"}
      proyecto -> {:ok, proyecto}
    end
  end

  def listar() do
    proyectos = Persistencia.leer_proyectos()

    if Enum.empty?(proyectos) do
      {:ok, "No hay proyectos registrados"}
    else
      {:ok, proyectos}
    end
  end

  @doc """
  Función que lista los proyectos que pertenecen a una categoría específica.
  """

  def listar_por_categoria(categoria) do
    proyectos = Persistencia.leer_proyectos()
    categoria_atom = String.to_atom(categoria)

    proyectos_filtrados = Enum.filter(proyectos, fn p ->
      p.categoria == categoria_atom
    end)

    {:ok, proyectos_filtrados}
  end

  @doc """
  Función que lista los proyectos por estado.
  """

  def listar_por_estado(estado) do
    proyectos = Persistencia.leer_proyectos()
    estado_atom = String.to_atom(estado)

    proyectos_filtrados = Enum.filter(proyectos, fn p ->
      p.estado == estado_atom
    end)

    {:ok, proyectos_filtrados}
  end

  @doc """
  Función que obtiene el proyecto asociado a un equipo.
  """

  def obtener_por_equipo(equipo_id) do
    proyectos = Persistencia.leer_proyectos()

    case Enum.find(proyectos, fn p -> p.equipo_id == equipo_id end) do
      nil -> {:error, "El equipo no tiene proyecto registrado"}
      proyecto -> {:ok, proyecto}
    end
  end

  # Funciones Privadas

  @doc """
  Función que valida que el equipo exista y que aún no tenga un proyecto asignado.
  """
  defp validar_equipo_sin_proyecto(equipo_id) do
    case GestionEquipos.obtener_info(equipo_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, equipo} ->
        if equipo.proyecto_id != nil do
          {:error, "El equipo ya tiene un proyecto registrado"}
        else
          {:ok, equipo}
        end
    end
  end

  @doc """
  Función que crea la estructura del proyecto con estado inicial :idea.
  """

  defp crear_proyecto(equipo_id, nombre, descripcion, categoria) do
    %Proyecto{
      id: Util.generar_id("proj"),
      equipo_id: equipo_id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: String.to_atom(categoria),
      estado: :idea,
      avances: []
    }
  end

  @doc """
   Función que guarda el proyecto agregándolo al archivo persistiendo la información.
  """

  defp guardar_proyecto(proyectos, nuevo_proyecto) do
    Persistencia.escribir_proyectos(proyectos ++ [nuevo_proyecto])
  end

  @doc """
  Función que vincula el proyecto al equipo seleccionado.
  """

  defp vincular_proyecto_a_equipo(equipo_id, proyecto_id) do
    GestionEquipos.actualizar_proyecto(equipo_id, proyecto_id)
  end

  @doc """
  Función que agrega un avance textual con timestamp al proyecto.
  """

  defp agregar_avance(proyectos, proyecto_id, nuevo_avance) do
    avance_con_timestamp = "#{Util.obtener_timestamp()}: #{nuevo_avance}"

    proyectos_actualizados = Enum.map(proyectos, fn p ->
      if p.id == proyecto_id do
        %{p | avances: p.avances ++ [avance_con_timestamp]}
      else
        p
      end
    end)

    Persistencia.escribir_proyectos(proyectos_actualizados)
  end
  
end
