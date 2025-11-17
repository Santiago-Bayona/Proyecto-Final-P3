defmodule Proyecto do

  @moduledoc """
  Módulo que define la estrutura de un proyecto dentro del sistema
  """

  @doc """
  Estructura base de un proyecto con sus atributos principales.
  """
  defstruct [:id, :equipo_id, :nombre, :descripcion, :categoria, :estado, :avances]

end
