defmodule GestionUsuarios do

  @moduledoc """
   Módulo encargado de gestionar toda la administración de usuarios dentro del sistema.
  """

  @doc """
  Función que realiza el proceso de inicio de sesión verificando que las credenciales coincidan.
  """

  def login(email, password) do
    usuarios = Persistencia.leer_usuarios()

    case Enum.find(usuarios, fn u -> u.email == email and u.password == password end) do
      nil -> {:error, "Credenciales incorrectas"}
      usuario -> {:ok, usuario}
    end
  end

  @doc """
  Función que permite registrar un nuevo usuario en el sistema, verificando si el email ya está registrado.
  """

  def registrar(nombre, email, password, tipo) do
    usuarios = Persistencia.leer_usuarios()

    if email_existe?(usuarios, email) do
      {:error, "El email ya está registrado"}
    else
      nuevo_usuario = crear_usuario(nombre, email, password, tipo)
      guardar_usuario(usuarios, nuevo_usuario)
      {:ok, "Usuario registrado exitosamente", nuevo_usuario}
    end
  end

  @doc """
  Función que permite obtener la información de un usuario dado su id.
  """

  def obtener_usuario(usuario_id) do
    usuarios = Persistencia.leer_usuarios()

    case Enum.find(usuarios, fn u -> u.id == usuario_id end) do
      nil -> {:error, "Usuario no encontrado"}
      usuario -> {:ok, usuario}
    end
  end

  @doc """
  Función que asigna un equipo a un usuario actualizando el campo "equipo_id".
  """

  def actualizar_equipo_usuario(usuario_id, equipo_id) do
    usuarios = Persistencia.leer_usuarios()

    usuarios_actualizados = Enum.map(usuarios, fn u ->
      if u.id == usuario_id do
        %{u | equipo_id: equipo_id}
      else
        u
      end
    end)

    Persistencia.escribir_usuarios(usuarios_actualizados)
    {:ok, "Usuario actualizado"}
  end

  @doc """
  Función que lista todos los usuarios registrados en el sistema.
  """

  def listar_usuarios() do
    usuarios = Persistencia.leer_usuarios()
    {:ok, usuarios}
  end

  @doc """
  Función que lista únicamente los usuarios cuyo tipo sea :mentor.
  """

  def listar_mentores() do
    usuarios = Persistencia.leer_usuarios()
    mentores = Enum.filter(usuarios, fn u -> u.tipo == :mentor end)
    {:ok, mentores}
  end

  # Funciones Privadas

  @doc """
  Función que verifica si el correo existe ya en la lista de usuarios.
  """
  defp email_existe?(usuarios, email) do
    Enum.any?(usuarios, fn u -> u.email == email end)
  end

  @doc """
  Función que construye la estructura %Usuario{} con un id generado automáticamente.
  """

  defp crear_usuario(nombre, email, password, tipo) do
    %Usuario{
      id: Util.generar_id("user"),
      nombre: nombre,
      email: email,
      password: password,
      tipo: tipo,
      equipo_id: nil
    }
  end

  @doc """
  Función que guarda un usuario agregándolo a la lista y escribiéndolo en el archivo.
  """

  defp guardar_usuario(usuarios, nuevo_usuario) do
    Persistencia.escribir_usuarios(usuarios ++ [nuevo_usuario])
  end
  
end
