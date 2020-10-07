defmodule PandemicModel.City do
  @moduledoc """
  This defines the City, with it's properties.
  """
  @city_keys ~w[id name colour links]a
  @city_colour ~w[blue red yellow black]a

  @enforce_keys @city_keys
  defstruct @city_keys

  #This is a very strict form of validation, as the function can only be found if the parameters are correct.
  defguardp is_city(id, name, colour, links) when is_atom(id)
                                              and is_binary(name)
                                              and colour in @city_colour
                                              and is_list(links)
                                              and length(links) > 0

  @spec new(id :: atom, name :: binary, colour :: :black | :blue | :red | :yellow, links :: [atom]) :: __MODULE__
  @doc """
  Creates a city.

  The error handling here is strict (as in no hints as to why it is wrong) as it is intended for internal use only.
  """
  def new(id, name, colour, links) when is_city(id, name, colour, links) do
    %__MODULE__{id: id, name: name, colour: colour, links: links}
  end
end
