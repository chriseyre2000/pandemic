defmodule PandemicModel.Disease do
  @disease_keys ~w[state unused_cubes]a
  @enforce_keys @disease_keys
  defstruct @disease_keys

  defguardp is_valid_state(state) when state in [:active, :cured, :erradicated] 

  def new(state \\ :active, unused_cubes \\ 24) when is_valid_state(state) do
    %__MODULE__{state: state, unused_cubes: unused_cubes  }
  end

  def remove_cubes(disease, count) do
    %__MODULE__{disease | unused_cubes: disease.unused_cubes - count}
  end  
  
  def diseases do
    ~w[red blue black yellow]a
  end  

end  