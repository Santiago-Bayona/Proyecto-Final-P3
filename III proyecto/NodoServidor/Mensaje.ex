defmodule Mensaje do

  @moduledoc """
  Módulo que define la estructura de un mensaje dentro del sistema.
  """

  @doc """
  Estrctura base del mensaje con sus atributos.
  """

  defstruct [:id, :equipo_id, :usuario_id, :contenido, :timestamp, :tipo]

end


 