defmodule Usuario do

  @moduledoc """
  Módulo que define la estructura de un usuario dentro del sistema.
  """

  @doc """
  Estructura base de un usuario con sus atributos principales.
  """

  defstruct [:id, :nombre, :email, :password, :tipo, :equipo_id]
  
end
