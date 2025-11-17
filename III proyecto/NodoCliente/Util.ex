defmodule Util do

  @moduledoc """
   Módulo de utilidades generales para el sistema Hackathon
  """

  @doc """
   Función que muestra un mensaje en la consola con formato estándar.
  """
  def mostrar_mensaje(mensaje) do
    IO.puts("\n[INFO] #{mensaje}")
  end

  @doc """
  Función que muestra un mensaje de error en consola.
  """

  def mostrar_error(mensaje) do
    IO.puts("\n[ERROR] #{mensaje}")
  end

  @doc """
  Función que muestra un mensaje de éxito con una marca visual de confirmación.
  """

  def mostrar_exito(mensaje) do
    IO.puts("\n[✓] #{mensaje}")
  end

  @doc """
  Función que solicita al usuario un valor de tipo texto.
  """
  def ingresar(prompt, :texto) do
    IO.gets("#{prompt} ")
  end

  @doc """
  Función que solicita al usuario un número.
  """
  def ingresar(prompt, :numero) do
    prompt
    |> IO.gets()
    |> String.trim()
    |> String.to_integer()
  end

  @doc """
  Función que genera un ID único concatenando un prefijo con el timestamp del sistema.
  """

  def generar_id(prefijo) do
    timestamp = :os.system_time(:millisecond)
    "#{prefijo}_#{timestamp}"
  end

  @doc """
  Función que obtiene la fecha y hora actual del sistema en formato legible.
  """
  def obtener_timestamp() do
    DateTime.utc_now()
    |> DateTime.to_string()
  end

  @doc """
  Función que limpia una cadena eliminando espacios al inicio y final, y la convierte a minúsculas.
  """

  def limpiar_input(texto) do
    texto
    |> String.trim()
    |> String.downcase()
  end
end
