defmodule Cookie do

   @moduledoc """
  Módulo encargado de la generación de claves seguras (cookies criptográficas).
  """

  @doc """
    Longitud de la llave en bytes.
  """
  @longitud_llave 128

  @doc """
  Función principal del módulo.
  """

  def main() do
    :crypto.strong_rand_bytes(@longitud_llave)
    |> Base.encode64()
    |> Util.mostrar_mensaje()
  end
end

Cookie.main()
