defmodule PandemicModel.Board do

  alias PandemicModel.Cities
  alias PandemicModel.Disease
  defstruct ~w[infection_deck infection_discard_pile outbreaks infection_rate disease_state cities_with_disease]a

  def new() do

    template_disease_count = Disease.diseases |>  Map.new(fn i -> {i, 0} end)

    %__MODULE__{
      infection_deck: Cities.all_keys() |> Enum.shuffle(),
      infection_discard_pile: [],
      infection_rate: 2,
      outbreaks: 0,
      disease_state: Disease.diseases |>  Map.new(fn i -> {i, Disease.new()} end),
      cities_with_disease: Cities.all_keys() |> Map.new(fn i -> {i, template_disease_count} end)
    }
  end
  
  def won?(board) do
    Enum.all?(Disease.diseases, fn d -> (board.disease_state[d]).state != :active end )
  end
  
  def lost?(model) do
    model.outbreaks == 8 or model.infection_deck == [] or Enum.any?( model.disease_state, &(&1  < 0) )  
  end

  def city_infection_count(board, city, colour) do
    board.cities_with_disease[city][colour]
  end

  def get_remaining_cubes_for_disease(board, colour) do
    board.disease_state[colour].unused_cubes
  end  
  
  defp remove_cubes_from_disease(%__MODULE__{disease_state: state } = board, colour, count) do
    state = Map.put(state, colour, Disease.remove_cubes(state[colour], count) )
    %__MODULE__{ board | disease_state: state  }
  end
  
  defp add_cube_to_city(board, city, colour, quantity) do
    infected_city_counts = board.cities_with_disease[city]
    infected_city_counts = Map.update(infected_city_counts, colour, 0, &(&1 + quantity))
    %__MODULE__{board | cities_with_disease: Map.put(board.cities_with_disease, city, infected_city_counts)}
  end  

  def infect(%__MODULE__{} = board, quantity \\ 1) do
    [infected_city | remainder] = board.infection_deck
    board = %{board | infection_deck: remainder, infection_discard_pile: [infected_city | board.infection_discard_pile]}
    infected_city_colour = Cities.city_colour(infected_city)
    board 
      |> remove_cubes_from_disease(infected_city_colour, quantity)
      |> add_cube_to_city(infected_city, infected_city_colour, quantity)
  end
  
  def setup_board(board) do
    board
      |> infect(3)
      |> infect(3)
      |> infect(3)
      |> infect(2)
      |> infect(2)
      |> infect(2)
      |> infect(1)
      |> infect(1)
      |> infect(1)
  end  

end  