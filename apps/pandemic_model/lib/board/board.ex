defmodule PandemicModel.Board do
  require Logger

  alias PandemicModel.{Cities, Disease, PlayerCard}

  @type t :: %__MODULE__{
    infection_deck: [atom],
    infection_discard_pile: [atom],
    outbreaks: non_neg_integer(),
    infection_rate: [non_neg_integer()],
    disease_state: map,
    cities_with_disease: map,
    research_stations: [atom],
    player_deck: [PlayerCard],
    player_discard_pile: [PlayerCard],
  }

  defstruct ~w[infection_deck infection_discard_pile outbreaks infection_rate disease_state cities_with_disease research_stations player_deck player_discard_pile]a

  @spec new :: __MODULE__
  @doc """
  Creates a new board.

  The board has not yet had the initial infection cards dealt.
  """
  def new() do
    zero_disease_count = Disease.diseases |>  Map.new(fn i -> {i, 0} end)

    %__MODULE__{
      infection_deck: Cities.all_keys() |> Enum.shuffle(),
      infection_discard_pile: [],
      infection_rate: [2, 2, 2, 3, 3, 4],
      outbreaks: 0,
      disease_state: Disease.diseases |>  Map.new(fn i -> {i, Disease.new()} end),
      cities_with_disease: Cities.all_keys() |> Map.new(fn i -> {i, zero_disease_count} end),
      research_stations: [:atlanta],
      player_deck: [],
      player_discard_pile: []
    }
  end

  ### Query API ###
  @spec research_station?(__MODULE__, atom) :: boolean
  @doc """
  Does the given city have a research station
  """
  def research_station?(board, city) do
    city in board.research_stations
  end

  @spec may_add_research_station?(__MODULE__) :: boolean
  @doc """
  Can another research station be added.
  """
  def may_add_research_station?(board) do
    Enum.count(board.research_stations) < 6
  end

  @spec current_infection_rate(__MODULE__) :: pos_integer()
  @doc """
  The current infection rate.
  This is the number cities that are infected at the end of the players turn.
  """
  def current_infection_rate(board) do
    hd(board.infection_rate)
  end

  @spec disease_active?(__MODULE__, atom) :: boolean
  @doc """
  Is the current disease active.
  """
  def disease_active?(board, disease_colour) do
    board.disease_state[disease_colour].state == :active
  end

  @spec disease_erradicated?(__MODULE__, atom) :: boolean
  @doc """
  Is the current disease erradicated.
  This means cured and no more on board.
  """
  def disease_erradicated?(board, disease_colour) do
    board.disease_state[disease_colour].state == :erradicated
  end

  @spec city_infection_count(__MODULE__.t(), city :: atom, colour :: atom) :: non_neg_integer()
  @doc """
  Returns the infection count for the disease colour in a given city
  """
  def city_infection_count(board, city, colour) do
    board.cities_with_disease[city][colour]
  end

  @spec diseased_cities( __MODULE__.t() ) :: map
  @doc """
  Provides a map of only the cities that have at least one infection count
  """
  def diseased_cities(board) do
    :maps.filter(fn _,v -> Map.values(v) |> Enum.sum() > 0 end, board.cities_with_disease)
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

  defp add_to_player_discard_pile(board, cards) do
    %{board | player_discard_pile: cards ++ board.player_discard_pile}
  end

  @spec increment_outbreak(__MODULE__.t()) :: __MODULE__.t()
  @doc """
  Records the number of outbreaks that have happened
  """
  def increment_outbreak(board) do
    %{board | outbreaks: board.outbreaks + 1}
  end

  defp record_disease_cured(%__MODULE__{disease_state: state } = board, colour) do
    state = Map.put(state, colour, Disease.cure_disease(state[colour]) )
    %{ board | disease_state: state  }
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
      |> return_disease_cube_to_pool(colour, to_remove)
      |> treat_disease_for_city(city, colour, to_remove)
      |> possible_disease_erradication(colour)
  end

  defp possible_disease_erradication(board, colour) do
    cond do
      disease_active?(board, colour) -> board
      true -> record_disease_cured(board, colour)
    end
  end

  defp return_disease_cube_to_pool(%__MODULE__{disease_state: state } = board, colour, count) do
    state = Map.put(state, colour, Disease.add_cubes(state[colour], count) )
    %__MODULE__{ board | disease_state: state  }
  end

  defp take_disease_cube_from_pool(%__MODULE__{disease_state: state } = board, colour, count) do
    state = Map.put(state, colour, Disease.remove_cubes(state[colour], count) )
    %__MODULE__{ board | disease_state: state  }
  end

  defp increase_city_disease_count(board, city, colour, quantity) do
    infected_city_counts = board.cities_with_disease[city]
    infected_city_counts = Map.update(infected_city_counts, colour, 0, &( min( &1 + quantity, 3)))
    %__MODULE__{board | cities_with_disease: Map.put(board.cities_with_disease, city, infected_city_counts)}
  end

  defp treat_disease_for_city(board, city, colour, count) do
    infected_city_counts = board.cities_with_disease[city]
    infected_city_counts = Map.update(infected_city_counts, colour, 0,  &(&1 - count))
    %__MODULE__{board | cities_with_disease: Map.put(board.cities_with_disease, city, infected_city_counts)}
  end

  defp move_top_card_to_discard_pile(board) do
    %{board | infection_deck: tl(board.infection_deck ), infection_discard_pile: Enum.concat([ hd(board.infection_deck)], board.infection_discard_pile )}
  end

  defp infect(%__MODULE__{} = board, quantity \\ 1) when quantity in [1,2,3] do
    infected_city  = hd(board.infection_deck)
    board = board
      |>  move_top_card_to_discard_pile()
    infected_city_colour = Cities.city_colour(infected_city)
    infected_city_count = city_infection_count(board, infected_city, infected_city_colour)

    cond do
      disease_erradicated?(board, infected_city_colour) ->
        board
      ((infected_city_count + quantity) < 4) ->
        board
        |> increase_city_disease_count(infected_city, infected_city_colour, quantity)
        |> take_disease_cube_from_pool(infected_city_colour, quantity)
      true ->
        board
        |> increase_city_disease_count(infected_city, infected_city_colour, quantity)
        |> take_disease_cube_from_pool(infected_city_colour, 3 - infected_city_count)
        |> trigger_outbreak(infected_city, [infected_city], infected_city_colour)
    end
  end

  defp trigger_outbreak(board, triggering_city, existing_infections, infection_colour) do
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
          |> increase_city_disease_count(infected_city, infection_colour, 1)
          |> take_disease_cube_from_pool(infection_colour, 1)
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

    cond do
      disease_erradicated?(board, epidemic_colour) ->
        board
      epidemic_city_disease_count == 0 ->
        board
        |> increase_city_disease_count(epidemic_city, epidemic_colour, 3)
        |> take_disease_cube_from_pool(epidemic_colour, 3)
      true ->
        board
        |> increase_city_disease_count(epidemic_city, epidemic_colour, max(3 - epidemic_city_disease_count, 0) )
        |> take_disease_cube_from_pool(epidemic_colour, max(3 - epidemic_city_disease_count, 0))
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

  @spec infect_cities(__MODULE__.t()) :: __MODULE__.t()
  @doc """
  This is the event at the end of the players turn during which a certain number of cities are infected.
  This can trigger further outbreaks.
  """
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

  @spec setup_board(__MODULE__.t()) :: __MODULE__.t()
  @doc """
  This places the initial disease counters on the board.
  """
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
end
