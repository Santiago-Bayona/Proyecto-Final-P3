defmodule Equipo do

  @moduledoc """
   Módulo que define la estructura de un equipo dentro del sistema.
  """

   @doc """
  Estructura base del equipo con sus atributos principales.
  """
  
  defstruct [:id, :nombre, :tema, :miembros, :proyecto_id, :activo]

end
