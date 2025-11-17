defmodule Persistencia do

  @moduledoc """
  Módulo encargado de gestionar la persistencia de datos del sistema utilizando
  archivos CSV como almacenamiento local.
  """

  # ============ USUARIOS ============

    @doc """
    Función que escribe la lista completa de usuarios en un archivo CSV.
    """
  def escribir_usuarios(lista_usuarios, nombre_archivo \\ "usuarios.csv") do
    headers = "id,nombre,email,password,tipo,equipo_id\n"
    contenido = Enum.map(lista_usuarios, fn %Usuario{id: id, nombre: nombre, email: email, password: password, tipo: tipo, equipo_id: equipo_id} ->
      "#{id},#{nombre},#{email},#{password},#{tipo},#{equipo_id || ""}\n"
    end)
    |> Enum.join()
    File.write(nombre_archivo, headers <> contenido)
  end

  @doc """
  Función que lee el archivo CSV de usuarios y lo convierte en una lista de structs "%Usuario{}".
  """
  def leer_usuarios(nombre_archivo \\ "usuarios.csv") do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn line ->
          case String.split(line, ",") do
            ["id", "nombre", "email", "password", "tipo", "equipo_id"] -> nil
            [id, nombre, email, password, tipo, equipo_id] ->
              %Usuario{
                id: id,
                nombre: nombre,
                email: email,
                password: password,
                tipo: String.to_atom(tipo),
                equipo_id: if(equipo_id == "", do: nil, else: equipo_id)
              }
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)
      {:error, _reason} ->
        []
    end
  end

  # ============ EQUIPOS ============

    @doc """
    Función que guarda todos los equipos en formato CSV.
    """
  def escribir_equipos(lista_equipos, nombre_archivo \\ "equipos.csv") do
    headers = "id,nombre,tema,miembros,proyecto_id,activo\n"
    contenido = Enum.map(lista_equipos, fn %Equipo{id: id, nombre: nombre, tema: tema, miembros: miembros, proyecto_id: proyecto_id, activo: activo} ->
      miembros_str = Enum.join(miembros || [], ";")
      "#{id},#{nombre},#{tema},#{miembros_str},#{proyecto_id || ""},#{activo}\n"
    end)
    |> Enum.join()
    File.write(nombre_archivo, headers <> contenido)
  end

  @doc """
  Función que lee el CSV de equipos y lo convierte en structs "%Equipo{}".
  """
  def leer_equipos(nombre_archivo \\ "equipos.csv") do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn line ->
          case String.split(line, ",") do
            ["id", "nombre", "tema", "miembros", "proyecto_id", "activo"] -> nil
            [id, nombre, tema, miembros_str, proyecto_id, activo] ->
              miembros = if miembros_str == "", do: [], else: String.split(miembros_str, ";")
              %Equipo{
                id: id,
                nombre: nombre,
                tema: tema,
                miembros: miembros,
                proyecto_id: if(proyecto_id == "", do: nil, else: proyecto_id),
                activo: String.to_atom(activo)
              }
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)
      {:error, _reason} ->
        []
    end
  end

  # ============ PROYECTOS ============
    @doc """
    Función que guarda todos los proyectos en un archivo CSV.
    """

  def escribir_proyectos(lista_proyectos, nombre_archivo \\ "proyectos.csv") do
    headers = "id,equipo_id,nombre,descripcion,categoria,estado,avances\n"
    contenido = Enum.map(lista_proyectos, fn %Proyecto{id: id, equipo_id: equipo_id, nombre: nombre, descripcion: descripcion, categoria: categoria, estado: estado, avances: avances} ->
      avances_str = Enum.join(avances || [], ";")
      descripcion_limpia = String.replace(descripcion || "", ",", "COMMA")
      "#{id},#{equipo_id},#{nombre},#{descripcion_limpia},#{categoria},#{estado},#{avances_str}\n"
    end)
    |> Enum.join()
    File.write(nombre_archivo, headers <> contenido)
  end

  @doc """
  Función que lee el archivo CSV de proyectos y reconstruye structs "%Proyecto{}".
  """

  def leer_proyectos(nombre_archivo \\ "proyectos.csv") do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn line ->
          case String.split(line, ",") do
            ["id", "equipo_id", "nombre", "descripcion", "categoria", "estado", "avances"] -> nil
            [id, equipo_id, nombre, descripcion, categoria, estado, avances_str] ->
              avances = if avances_str == "", do: [], else: String.split(avances_str, ";")
              descripcion_restaurada = String.replace(descripcion, "COMMA", ",")
              %Proyecto{
                id: id,
                equipo_id: equipo_id,
                nombre: nombre,
                descripcion: descripcion_restaurada,
                categoria: String.to_atom(categoria),
                estado: String.to_atom(estado),
                avances: avances
              }
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)
      {:error, _reason} ->
        []
    end
  end

  # ============ MENSAJES ============
    @doc """
    Función que guarda todos los mensajes enviados en sus respectivos equipos.
    """
  def escribir_mensajes(lista_mensajes, nombre_archivo \\ "mensajes.csv") do
    headers = "id,equipo_id,usuario_id,contenido,timestamp,tipo\n"
    contenido = Enum.map(lista_mensajes, fn %Mensaje{id: id, equipo_id: equipo_id, usuario_id: usuario_id, contenido: contenido, timestamp: timestamp, tipo: tipo} ->
      contenido_limpio = String.replace(contenido, ",", "COMMA")
      "#{id},#{equipo_id},#{usuario_id},#{contenido_limpio},#{timestamp},#{tipo}\n"
    end)
    |> Enum.join()
    File.write(nombre_archivo, headers <> contenido)
  end

  @doc """
  Función que lee el archivo CSV de mensajes y lo convierte en structs "%Mensaje{}".
  """

  def leer_mensajes(nombre_archivo \\ "mensajes.csv") do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn line ->
          case String.split(line, ",") do
            ["id", "equipo_id", "usuario_id", "contenido", "timestamp", "tipo"] -> nil
            [id, equipo_id, usuario_id, contenido, timestamp, tipo] ->
              contenido_restaurado = String.replace(contenido, "COMMA", ",")
              %Mensaje{
                id: id,
                equipo_id: equipo_id,
                usuario_id: usuario_id,
                contenido: contenido_restaurado,
                timestamp: timestamp,
                tipo: String.to_atom(tipo)
              }
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)
      {:error, _reason} ->
        []
    end
  end

  # ============ FEEDBACK ============
    @doc """
    Función que guarda en CSV las entradas de feedback de mentores.
    """
  def escribir_feedback(lista_feedback, nombre_archivo \\ "feedback.csv") do
    headers = "id,proyecto_id,mentor_id,contenido,timestamp\n"
    contenido = Enum.map(lista_feedback, fn %Feedback{id: id, proyecto_id: proyecto_id, mentor_id: mentor_id, contenido: contenido, timestamp: timestamp} ->
      contenido_limpio = String.replace(contenido, ",", "COMMA")
      "#{id},#{proyecto_id},#{mentor_id},#{contenido_limpio},#{timestamp}\n"
    end)
    |> Enum.join()
    File.write(nombre_archivo, headers <> contenido)
  end

  @doc """
  Función que lee el archivo CSV de feedback y devuelve structs "%Feedback{}".
  """
  def leer_feedback(nombre_archivo \\ "feedback.csv") do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn line ->
          case String.split(line, ",") do
            ["id", "proyecto_id", "mentor_id", "contenido", "timestamp"] -> nil
            [id, proyecto_id, mentor_id, contenido, timestamp] ->
              contenido_restaurado = String.replace(contenido, "COMMA", ",")
              %Feedback{
                id: id,
                proyecto_id: proyecto_id,
                mentor_id: mentor_id,
                contenido: contenido_restaurado,
                timestamp: timestamp
              }
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)
      {:error, _reason} ->
        []
    end
  end
end
