defmodule PandemicModel.City do
  @city_keys ~w[id name colour links]a
  @city_colour ~w[blue red yellow black]a

  @enforce_keys @city_keys
  defstruct @city_keys

  #This is a very strict form of validation, as the function can only be found if the parameters are correct.
  defguard is_city(id, name, colour, links) when is_atom(id) and is_binary(name) and colour in @city_colour and is_list(links) and length(links) > 0
  
  def new(id, name, colour, links) when is_city(id, name, colour, links) do
    %__MODULE__{id: id, name: name, colour: colour, links: links}
  end  
end  