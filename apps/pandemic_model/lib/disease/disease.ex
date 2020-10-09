defmodule PandemicModel.Disease do
  @moduledoc """
  Handles the disease bank for a disease.
  """
  @disease_keys ~w[state]a
  @enforce_keys @disease_keys
  defstruct @disease_keys

  defguardp is_valid_state(state) when state in [:active, :cured, :erradicated]

  def new(state \\ :active) when is_valid_state(state) do
    %__MODULE__{state: state  }
  end

  def cure_disease(disease, remaining_diseases) do
    if remaining_diseases == 0 do
      %__MODULE__{disease | state: :erradicated}
    else
      %__MODULE__{disease | state: :cured}
    end
  end

  def diseases do
    ~w[red blue black yellow]a
  end

end
