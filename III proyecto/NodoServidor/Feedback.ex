defmodule Feedback do

  @moduledoc """
  Módulo que define la estructura de un Feedback dentro del sistema.
  """

  @doc """
  Estructura base del Feedback con sus atributos principales.
  """

  defstruct [:id, :proyecto_id, :mentor_id, :contenido, :timestamp]

end
