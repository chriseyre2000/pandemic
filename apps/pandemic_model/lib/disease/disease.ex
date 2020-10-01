defmodule PandemicModel.Disease do
  @disease_keys ~w[state unused_cubes]a
  @enforce_keys @disease_keys
  defstruct @disease_keys

  defguard is_valid_state(state) when state in [:active, :cured, :erradicated] 

  def new() do
    %__MODULE__{state: :active, unused_cubes: 24  }
  end

  def remove_cubes(disease, count) do
    %{disease | unused_cubes: disease.unused_cubes - count}
  end  
  
  def diseases do
    ~w[red blue black yellow]a
  end  

end  