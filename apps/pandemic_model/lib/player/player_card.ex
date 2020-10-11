defmodule PandemicModel.PlayerCard do
  @moduledoc """
  Defines the cards that form the player deck.
  """
  # @card_type ~w[city event epidemic]a

  defstruct [:city, :type, :action, :stored]

  def new_city(city) do
    %__MODULE__{city: city, type: :city}
  end

  def new_epidemic do
    %__MODULE__{type: :epidemic}
  end

  def new_event(action) do
    %__MODULE__{type: :event, action: action, stored: false}
  end

  def mark_stored(%__MODULE__{} = card) do
    %{card | stored: true}
  end
end
