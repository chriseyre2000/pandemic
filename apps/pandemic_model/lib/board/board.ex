defmodule PandemicModel.Board do
  @moduledoc """
  Defines the board and interactions with the game.
  """
  alias PandemicModel.{Board, Cities, Disease, PlayerCard}

  @type t :: %Board{
    infection_deck: [atom],
    infection_discard_pile: [atom],
    outbreaks: non_neg_integer(),
    infection_rate: [non_neg_integer()],
    disease_state: map,
    cities_with_disease: map,
    research_stations: [atom],
    player_deck: [PlayerCard],
    player_discard_pile: [PlayerCard],
    quiet_night: bool
  }

  defstruct ~w[infection_deck infection_discard_pile outbreaks
               infection_rate disease_state cities_with_disease
               research_stations player_deck player_discard_pile
               quiet_night medic_location quarentene_specialist_location]a

  @spec new :: Board.t()
  @doc """
  Creates a new board.

  The board has not yet had the initial infection cards dealt.
  """
  def new do
    zero_disease_count = Disease.diseases |>  Map.new(&{&1, 0})

    %Board{
      infection_deck: Cities.all_keys() |> Enum.shuffle(),
      infection_discard_pile: [],
      infection_rate: [2, 2, 2, 3, 3, 4],
      outbreaks: 0,
      disease_state: Disease.diseases |>  Map.new(fn i -> {i, Disease.new()} end),
      cities_with_disease: Cities.all_keys() |> Map.new(fn i -> {i, zero_disease_count} end),
      research_stations: [:atlanta],
      player_deck: [],
      player_discard_pile: [],
      quiet_night: false,
      medic_location: nil,
      quarentene_specialist_location: nil
    }
  end

  ### Query API ###
  @spec research_station?(Board.t(), atom) :: boolean
  @doc """
  Does the given city have a research station
  """
  def research_station?(board, city) do
    city in board.research_stations
  end

  @spec may_add_research_station?(Board.t()) :: boolean
  @doc """
  Can another research station be added.
  """
  def may_add_research_station?(board) do
    Enum.count(board.research_stations) < 6
  end

  @spec current_infection_rate(Board.t()) :: pos_integer()
  @doc """
  The current infection rate.
  This is the number cities that are infected at the end of the players turn.
  """
  def current_infection_rate(%Board{infection_rate: []} = _board) do
    4
  end

  def current_infection_rate(%Board{infection_rate: [current_rate|_]}) do
    current_rate
  end

  @spec disease_active?(Board.t(), atom) :: boolean
  @doc """
  Is the current disease active.
  """
  def disease_active?(%Board{} = board, disease_colour) do
    board.disease_state[disease_colour].state == :active
  end

  @spec disease_erradicated?(Board.t(), atom) :: boolean
  @doc """
  Is the current disease erradicated.
  This means cured and no more on board.
  """
  def disease_erradicated?(%Board{} = board, disease_colour) do
    board.disease_state[disease_colour].state == :erradicated
  end

  @spec forecast_cards?(Board.t(), [PlayerCard]) :: boolean
  def forecast_cards?(%Board{} = board, forecast_cards) do
    (board.infection_deck |> Enum.take(6) |> Enum.sort) == (forecast_cards |> Enum.sort())
  end

  @spec city_infection_count(__MODULE__.t(), city :: atom, colour :: atom) :: non_neg_integer()
  @doc """
  Returns the infection count for the disease colour in a given city
  """
  def city_infection_count(board, city, colour) do
    board.cities_with_disease[city][colour]
  end

  @spec diseased_cities(__MODULE__.t()) :: map
  @doc """
  Provides a map of only the cities that have at least one infection count
  """
  def diseased_cities(board) do
    :maps.filter(fn _, v -> v |> Map.values() |> Enum.sum() > 0 end, board.cities_with_disease)
  end

  def total_disease_on_board(board) do
    board.cities_with_disease |> Map.values() |> Enum.map( &Map.values/1 ) |> List.flatten() |> Enum.sum()
  end

  def total_disease_on_board(board, colour) do
    board.cities_with_disease |> Map.values() |> Enum.map( fn i -> Map.get(i, colour) end) |> Enum.sum()
  end

  ### Command API ###

  @spec add_research_station(__MODULE__.t(), city :: atom) :: __MODULE__
  @doc """
  Adds a research station for the supplied city.

  Is idempotent since you can only one research station

  It will ignore attempts to add research stations once the limit has been reached.
  """
  def add_research_station(%__MODULE__{research_stations: existing_stations} = board, city) do
    cond do
      city in existing_stations -> board
      not may_add_research_station?(board) -> board
      true -> %{board | research_stations: [city | existing_stations]}
    end
  end

  @spec cure_disease(PandemicModel.Board.t(), [PlayerCard]) :: PandemicModel.Board.t()
  @doc """
  Cures the disease with the supplied list of cards
  """
  def cure_disease(board, cards) do
    disease_colour = cards
      |> hd()
      |> Map.get(:city)
      |> Cities.city_colour()
    board
      |> record_disease_cured(disease_colour)
      |> add_to_player_discard_pile(cards)
  end

  def add_to_player_discard_pile(board, cards) when is_list(cards) do
    %{board | player_discard_pile: cards ++ board.player_discard_pile}
  end

  def add_to_player_discard_pile(board, card) do
    %{board | player_discard_pile: [card] ++ board.player_discard_pile}
  end

  @spec increment_outbreak(__MODULE__.t()) :: __MODULE__.t()
  @doc """
  Records the number of outbreaks that have happened
  """
  def increment_outbreak(board) do
    %{board | outbreaks: board.outbreaks + 1}
  end

  @spec enable_quiet_night(PandemicModel.Board.t()) :: PandemicModel.Board.t()
  def enable_quiet_night(%__MODULE__{} = board) do
    %{board | quiet_night: true}
  end

  defp disable_quiet_night(board) do
    %{board | quiet_night: false}
  end

  defp record_disease_cured(%__MODULE__{disease_state: state } = board, colour) do
    state = Map.put(state, colour, Disease.cure_disease(state[colour], board |> Board.total_disease_on_board(colour)) )
    %{board | disease_state: state}
  end

  @spec treat_disease(__MODULE__.t(), city :: atom, colour :: atom) :: __MODULE__.t()
  def treat_disease(%__MODULE__{} = board, city, colour) do
    disease_count = city_infection_count(board, city, colour)
    to_remove =
      if disease_active?(board, colour) do
        1
      else
        disease_count
      end
    board
      |> remove_n_disease_of_colour_and_consider_erradicate(city, colour, to_remove)
  end

  defp remove_n_disease_of_colour_and_consider_erradicate(board, city, colour, to_remove) do
    board
      |> treat_disease_for_city(city, colour, to_remove)
      |> possible_disease_erradication(colour)
  end

  @spec player_arrives_in_city(Board, role :: atom, city :: atom, travel_type :: atom) :: Board
  def player_arrives_in_city(board, :medic, city, _travel_type) do
    board
      |> medic_arrives_in_city(city)
      |> remove_cured_diseases_from_city(city)
  end

  def player_arrives_in_city(board, :quarentene_specialist, city, _travel_type) do
    %{board | quarentene_specialist_location: city}
  end

  def player_arrives_in_city(board, _role, _city, _travel_type) do
    board
  end

  defp medic_arrives_in_city(board, city) do
    %{board | medic_location: city}
  end

  defp remove_cured_diseases_from_city(board, city) do
   Disease.diseases
     |> Enum.reduce(board, fn disease, board -> remove_cured_diseases_from_city(board, city, disease) end)
  end

  defp remove_cured_diseases_from_city(board, city, colour) do
    if disease_active?(board, colour) do
      board
    else
      disease_count = city_infection_count(board, city, colour)
      board
        |> remove_n_disease_of_colour_and_consider_erradicate(city, colour, disease_count)
    end
  end

  defp possible_disease_erradication(board, colour) do
    if disease_active?(board, colour) do
      board
    else
      record_disease_cured(board, colour)
    end
  end

  defp increase_city_disease_count(board, city, colour, quantity) do
    infected_city_counts = board.cities_with_disease[city] |> Map.update(colour, 0, &(min(&1 + quantity, 3)))
    board |> record_infected_city_count(city, infected_city_counts)
  end

  defp treat_disease_for_city(board, city, colour, count) do
    infected_city_counts = board.cities_with_disease[city]
    infected_city_counts = Map.update(infected_city_counts, colour, 0,  &(&1 - count))
    board |> record_infected_city_count(city, infected_city_counts)
  end

  defp record_infected_city_count(board, city, infected_city_counts) do
    %{board | cities_with_disease: board.cities_with_disease |> Map.put(city, infected_city_counts)}
  end

  defp move_top_card_to_discard_pile(board) do
    %{board | infection_deck: tl(board.infection_deck), infection_discard_pile: Enum.concat([hd(board.infection_deck)], board.infection_discard_pile)}
  end

  defp trigger_outbreak(board, triggering_city, existing_infections, infection_colour) do
    board = board
      |> increment_outbreak()
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
          |> increase_city_disease_count(infected_city, infection_colour, 1)
          |> infect_outbreak(tail, existing_infections, infection_colour)
    end
  end

  defp update_infection_rate(%Board{} = board) do
    %{board | infection_rate: tl(board.infection_rate)}
  end

  defp prevent_outbreak?(%Board{} = board, city, disease_colour) do
    cond do
      disease_erradicated?(board, disease_colour) -> true
      #Quarentene Specialist prevents diseases from being placed in the city they are in and all connected cities.
      city == board.quarentene_specialist_location -> true
      board.quarentene_specialist_location != nil and city in Cities.city_links(board.quarentene_specialist_location) -> true
      #Medic prevents cured diseases from being played in the city that they are in
      city == board.medic_location and not disease_active?(board, city) -> true
      true -> false
    end
  end

  defp infect(%__MODULE__{infection_deck: [infected_city | _tail ] } = board, quantity \\ 1) when quantity in [1, 2, 3] do
    board = board
      |>  move_top_card_to_discard_pile()
    infected_city_colour = Cities.city_colour(infected_city)
    infected_city_count = city_infection_count(board, infected_city, infected_city_colour)

    cond do
      prevent_outbreak?(board, infected_city, infected_city_colour) ->
        board
      ((infected_city_count + quantity) < 4) ->
        board
        |> increase_city_disease_count(infected_city, infected_city_colour, quantity)
      true ->
        board
        |> increase_city_disease_count(infected_city, infected_city_colour, quantity)
        |> trigger_outbreak(infected_city, [infected_city], infected_city_colour)
    end
  end

  @spec epidemic(PandemicModel.Board.t()) :: PandemicModel.Board.t()
  @doc """
  Handle an epidemic - triggered by drawing a player card
  """
  def epidemic(%Board{} = board) do
    board = board
      |> update_infection_rate()
    epidemic_city = List.last(board.infection_deck)
    epidemic_colour = Cities.city_colour(epidemic_city)
    epidemic_city_disease_count = city_infection_count(board, epidemic_city, epidemic_colour)

    board = %Board{board | infection_deck: Enum.drop(board.infection_deck, -1)}

    cond do
      prevent_outbreak?(board, epidemic_city, epidemic_colour) ->
        board
      epidemic_city_disease_count == 0 ->
        board
        |> increase_city_disease_count(epidemic_city, epidemic_colour, 3)
      true ->
        board
        |> increase_city_disease_count(epidemic_city, epidemic_colour, max(3 - epidemic_city_disease_count, 0) )
        |> trigger_outbreak(epidemic_city, [epidemic_city], epidemic_colour)
    end
    |> reinfect(epidemic_city)
  end

  defp reinfect(%Board{} = board, epidemic_city) do
    new_infection_deck = [epidemic_city | board.infection_discard_pile]
      |> Enum.shuffle
      |> Enum.concat(board.infection_deck)

    %{board | infection_deck: new_infection_deck , infection_discard_pile: []}
  end

  @spec infect_cities(__MODULE__.t()) :: __MODULE__.t()
  @doc """
  This is the event at the end of the players turn during which a certain number of cities are infected.
  This can trigger further outbreaks.
  """
  def infect_cities(board) do
    if board.quiet_night do
      board
        |> disable_quiet_night()
    else
      additional_infect(board, current_infection_rate(board))
    end
  end

  defp additional_infect(board, 0) do
    board
  end

  defp additional_infect(board, remaining_times) do
    board
      |> infect()
      |> additional_infect(remaining_times - 1)
  end

  @spec setup_board(__MODULE__.t()) :: __MODULE__.t()
  @doc """
  This places the initial disease counters on the board.
  """
  def setup_board(board) do
    [3, 3, 3, 2, 2, 2, 1, 1, 1]
      |> Enum.reduce(board, fn(quantity, board) -> infect(board, quantity) end)
  end

  @spec add_player_deck(PandemicModel.Board.t()) :: PandemicModel.Board.t()
  def add_player_deck(%__MODULE__{} = board) do
    all_city_cards = Cities.all_cities
      |> Enum.map(&(PlayerCard.new_city(&1.id)))

    event_cards = [
      PlayerCard.new_event(:government_grant),
      PlayerCard.new_event(:airlift),
      PlayerCard.new_event(:quiet_night),
      PlayerCard.new_event(:forecast),
      PlayerCard.new_event(:resiliant_population),
    ]

    %{board | player_deck: all_city_cards ++ event_cards |> Enum.shuffle(), player_discard_pile: []}
  end

  def remove_from_infection_discard_pile(%__MODULE__{} = board, city) do
    %{board | infection_discard_pile: board.infection_discard_pile -- [city]}
  end

  def reorder_for_forecast(%__MODULE__{} = board, infection_cards) do
    %{board | infection_deck: infection_cards ++ ( board.infection.deck |> Enum.drop(6))}
  end
end
