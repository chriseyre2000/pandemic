defmodule PandemicModel.Board do
  require Logger

  alias PandemicModel.Cities
  alias PandemicModel.Disease
  defstruct ~w[infection_deck infection_discard_pile outbreaks infection_rate disease_state cities_with_disease]a

  def new() do
    template_disease_count = Disease.diseases |>  Map.new(fn i -> {i, 0} end)

    %__MODULE__{
      infection_deck: Cities.all_keys() |> Enum.shuffle(),
      infection_discard_pile: [],
      infection_rate: [2, 2, 2, 3, 3, 4],
      outbreaks: 0,
      disease_state: Disease.diseases |>  Map.new(fn i -> {i, Disease.new()} end),
      cities_with_disease: Cities.all_keys() |> Map.new(fn i -> {i, template_disease_count} end)
    }
  end

  def current_infection_rate(board) do
    board.infection_rate |> List.first
  end  
  
  #This ignores the superbug challenge for now
  def won?(board) do
    board.disease_state |> Map.values |> Enum.all?( &(&1.state not in [:active]))
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
  
  def increment_outbreak(board) do
    %{board | outbreaks: board.outbreaks + 1}
  end  
  
  defp remove_cubes_from_disease(%__MODULE__{disease_state: state } = board, colour, count) do
    state = Map.put(state, colour, Disease.remove_cubes(state[colour], count) )
    %__MODULE__{ board | disease_state: state  }
  end
  
  def add_cube_to_city(board, city, colour, quantity) do
    infected_city_counts = board.cities_with_disease[city]
    infected_city_counts = Map.update(infected_city_counts, colour, 0, &( min( &1 + quantity, 3)))
    %__MODULE__{board | cities_with_disease: Map.put(board.cities_with_disease, city, infected_city_counts)}
  end  

  def move_top_card_to_discard_pile(board) do
    %{board | infection_deck: tl(board.infection_deck ), infection_discard_pile: Enum.concat([ hd(board.infection_deck)], board.infection_discard_pile )}
  end  

  defp infect(%__MODULE__{} = board, quantity \\ 1) when quantity in [1,2,3] do
    infected_city  = hd(board.infection_deck)
    board = move_top_card_to_discard_pile(board)
    infected_city_colour = Cities.city_colour(infected_city)
    infected_city_count = city_infection_count(board, infected_city, infected_city_colour)


    if ((infected_city_count + quantity) < 4) do
      board 
      |> add_cube_to_city(infected_city, infected_city_colour, quantity)
      |> remove_cubes_from_disease(infected_city_colour, quantity)
    else
      board 
      |> add_cube_to_city(infected_city, infected_city_colour, quantity)
      |> remove_cubes_from_disease(infected_city_colour, 3 - infected_city_count)
      |> trigger_outbreak(infected_city, [infected_city], infected_city_colour)
    end
   
  end

  def trigger_outbreak(board, triggering_city, existing_infections, infection_colour) do
    board = board |> increment_outbreak()
    cities_to_infect = Cities.find_by(triggering_city).links -- existing_infections
    existing_infections = cities_to_infect ++ existing_infections 

    infect_outbreak(board, cities_to_infect, existing_infections, infection_colour)
  end
  
  defp infect_outbreak(board, [], _, _) do
    board 
  end
  
  defp infect_outbreak(board, [infected_city | tail], existing_infections, infection_colour) do 
    case city_infection_count(board, infected_city, infection_colour) do
      3 -> 
        board = increment_outbreak(board)
        new_infections = Cities.find_by(infected_city).links -- existing_infections
        infect_outbreak(board, tail ++ new_infections, existing_infections ++ new_infections, infection_colour)
      _ -> 
        board
          |> add_cube_to_city(infected_city, infection_colour, 1)
          |> remove_cubes_from_disease(infection_colour, 1)  
          |> infect_outbreak(tail, existing_infections, infection_colour)
    end  
  end

  defp update_infection_rate(board) do
    %__MODULE__{board | infection_rate: tl(board.infection_rate)}
  end  
  
  def epidemic(board) do
    board = board |> update_infection_rate()
    epidemic_city = List.last(board.infection_deck)
    epidemic_colour = Cities.city_colour(epidemic_city)
    epidemic_city_disease_count = city_infection_count(board, epidemic_city, epidemic_colour)

    board = %__MODULE__{board | infection_deck: Enum.drop(board.infection_deck, -1)}


    if epidemic_city_disease_count == 0 do
      board
      |> add_cube_to_city(epidemic_city, epidemic_colour, 3)
      |> remove_cubes_from_disease(epidemic_colour, 3)  
    else
      board
      |> add_cube_to_city(epidemic_city, epidemic_colour, max(3 - epidemic_city_disease_count, 0) )
      |> remove_cubes_from_disease(epidemic_colour, max(3 - epidemic_city_disease_count, 0))
      |> trigger_outbreak(epidemic_city, [epidemic_city], epidemic_colour)
    end    
    |> reinfect(epidemic_city)
  end
  
  def reinfect(board, epidemic_city) do
    new_infection_deck = [epidemic_city | board.infection_discard_pile] 
      |> Enum.shuffle 
      |> Enum.concat( board.infection_deck )

    %__MODULE__{board | infection_deck: new_infection_deck , infection_discard_pile: []}
  end

  def infect_cities(board) do
    additional_infect(board, current_infection_rate(board))
  end 
  
  defp additional_infect(board, 0) do
    board
  end 

  defp additional_infect(board, remaining_times) do
    board 
      |> infect()
      |> additional_infect(remaining_times - 1)
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