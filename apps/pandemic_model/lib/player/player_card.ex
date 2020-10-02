defmodule PandemicModel.PlayerCard do
  # @card_type ~w[city event epidemic]a
  
  defstruct [:city, :type, :action]
  
  def new_city(city) do
    %__MODULE__{city: city, type: :city}
  end
  
  def new_epidemic() do
    %__MODULE__{type: :epidemic}  
  end
  
  def new_event(action) do
    %__MODULE__{type: :event, action: action}
  end  
end  