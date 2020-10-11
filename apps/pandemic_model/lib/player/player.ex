defmodule PandemicModel.Player do
@moduledoc """
This holds the structure and behaviour of the Player.
"""
  alias PandemicModel.{Board, Cities, Player, PlayerCard}
  @player_keys ~w[role city cards]a

  @enforce_keys @player_keys
  defstruct @player_keys

  @spec new(atom(), atom(), [atom()]) :: PandemicModel.Player
  def new(role, city \\ :atlanta, cards \\ []) do
    %Player{role: role, city: city, cards: cards}
  end

  @doc """
  Adds a card to the player
  """
  def add_card(%Player{} = player, %PlayerCard{} = card) do
    %{player | cards: [card| player.cards]}
  end

  def add_cards(%Player{} = player, []) do
    player
  end

  def add_cards(%Player{} = player, [card | remaining_cards]) do
    player
      |> Player.add_card(card)
      |> Player.add_cards(remaining_cards)
  end

  def drive_ferry(%Player{role: role} = player, destination, board) do
    if destination in Cities.city_links(player.city) do
      {
        :ok,
        %{player | city: destination},
        board |> Board.player_arrives_in_city(role, destination, :drive_ferry)
      }
    else
      {:error, "Can't drive/ferry from #{ Cities.city_name(player.city)} to #{Cities.city_name(destination)}" }
    end
  end

  def direct_flight(%Player{role: role} = player, %PlayerCard{:type => :city, :city => destination}, board) do
    {
      :ok,
      %{player | city: destination},
      board |> Board.player_arrives_in_city(role, destination, :direct_flight)
    }
  end

  def direct_flight(%Player{}, %PlayerCard{:type => type} = _card, _board) do
    {:error, "That's an #{type} card, you need a city card for a direct flight."}
  end

  def charter_flight(%Player{role: role} = player, %PlayerCard{:type => :city, :city => city}, destination, board) do
    if city == player.city do
      {
       :ok,
       %{player | city: destination},
       board |> Board.player_arrives_in_city(role, destination, :charter_flight)
      }
    else
      {:error, "You are currently in #{ Cities.city_name(player.city)} but the card was for #{ Cities.city_name(city)}"}
    end
  end

  def charter_flight(%Player{} = _player, %PlayerCard{:type => type}, _destination, _board) do
    {:error, "That's an #{type} card, you need a city card for a charter flight."}
  end

  def shuttle_flight(%Player{role: role} = player, destination, %Board{} = board) do
    cond do
      not Board.research_station?(board, player.city) -> {:error, "You are in #{ Cities.city_name(player.city)} which does not have a research station."}
      not Board.research_station?(board, destination) -> {:error, "There is no research station at #{ Cities.city_name(destination)}"}
      true ->
        {
          :ok,
          %{player | city: destination},
          board |> Board.player_arrives_in_city(role, destination, :shuttle_flight)
        }
    end
  end

  def build_a_research_station(%Player{} = player, %Board{} = board) do
    cond do
      not Board.may_add_research_station?(board) -> {:error, "We already have 6 reasearch stations, can't build more"}
      Board.research_station?(board, player.city) -> {:error, "There is already a research station at #{ Cities.city_name(player.city)}"}
      true -> {:ok, player, Board.add_research_station(board, player.city)}
    end
  end

  def treat_disease(%Player{} = player, colour, board) do
    if Board.city_infection_count(board, player.city, colour) == 0 do
      {:error, "No disease to cure here"}
    else
      {:ok, player, Board.treat_disease(board, player.city, colour)}
    end
  end

  def share_knowledge(%Player{} = player, %Player{} = other_player, %PlayerCard{:type => :city, :city => city} = card, board ) do
    cond do
      player.city != other_player.city -> {:error, "You need to be in the same city to share knowledge"}
      invalid_city?(player, other_player, card) -> {:error, "You need to be in the same city as the card to share knowledge"}
      card in player.cards -> {:ok,
                                %{player | cards: player.cards -- [card]},
                                %{other_player | cards: other_player.cards ++ [card]},
                                board}
      card in other_player.cards -> {:ok, %{player | cards: player.cards ++ [card] }, %{other_player | cards: other_player.cards -- [card]}, board}
      true -> {:error, "Neither of you had the card for #{Cities.city_name(city)}"}
    end
  end

  def share_knowledge(%Player{} = _player, %Player{} = _otherPlayer, %PlayerCard{:type => type}, _board) do
    {:error, "That's a #{type} card, you need a city card to share knowledge."}
  end

  defp invalid_city?(%Player{} = player_one, %Player{} = other_player, %PlayerCard{:type => :city, :city => city} = card) do
    cond do
      player_one.role == :researcher and card in player_one.cards -> false
      other_player.role == :researcher and card in other_player.cards -> false
      player_one.city != city -> true
      true -> false
    end
  end

  def cure_disease(%Player{role: role} = player, cards, %Board{} = board) do
    cond do
      role != :scientist and Enum.count(cards) != 5 -> {:error, "You need 5 cards and only supplied #{Enum.count(cards)}"}
      role == :scientist and Enum.count(cards) != 4 -> {:error, "You need 4 cards and only supplied #{Enum.count(cards)}"}
      cards |> Enum.any?(&(&1.type != :city)) -> {:error, "All the cards need to be city cards"}
      cards -- player.cards != [] -> {:error, "You don't have those cards"}
      role != :scientist and cards |> Enum.map(&(&1.city)) |> Enum.map(&Cities.city_colour/1) |> Enum.frequencies() |> Map.values != [5] -> {:error, "You don't have 5 cards of the same colour"}
      role == :scientist and cards |> Enum.map(&(&1.city)) |> Enum.map(&Cities.city_colour/1) |> Enum.frequencies() |> Map.values != [4] -> {:error, "You don't have 4 cards of the same colour"}
      not Board.disease_active?(board, cards |> hd() |> Map.get(:city) |> Cities.city_colour()) -> {:error, "Disease has already been cured"}
      true -> {:ok, %{player | cards: player.cards -- cards }, Board.cure_disease(board, cards) }
    end
  end

  def government_grant(%Player{cards: cards} = player, city, board) do
    government_grant_card = cards |> Enum.find(&(&1.action == :government_grant))
    cond do
       government_grant_card == nil -> {:error, "You don't have the government grant card" }
       false == board |> Board.may_add_research_station?() -> {:error, "There are already 6 research stations"}
       board |> Board.research_station?(city) -> {:error, "There is already a research station there"}
       true ->
         board = board
           |> Board.add_to_player_discard_pile(government_grant_card)
           |> Board.add_research_station(city)

        {:ok, %{player | cards: player.cards -- [government_grant_card] }, board }
    end
  end

  def airlift_self(%Player{role: role, cards: cards} = player, city, board) do
    airlift_card = cards |> Enum.find(&(&1.action == :airlift_card))

    cond do
      airlift_card == nil -> {:error, "You don't have the airlift card"}
      player.city == city -> {:error, "You are already in #{Cities.city_name(city)}"}
      true ->
        {
          :ok,
          %{player | city: city, cards: cards -- [airlift_card]},
          board
            |> Board.add_to_player_discard_pile(airlift_card)
            |> Board.player_arrives_in_city(role, city, :airlift)
        }
    end
  end

  def airlift_other(%Player{cards: cards} = player, %Player{role: role} = travelling_player, city, board) when player != travelling_player  do
    airlift_card = cards |> Enum.find(&(&1.action == :airlift_card))

    cond do
      airlift_card == nil -> {:error, "You don't have the airlift card"}
      travelling_player.city == city -> {:error, "#{travelling_player.role} is already in #{Cities.city_name(city)}"}
      true ->
        {
          :ok,
          %{player | cards: cards -- [airlift_card]},
          %{travelling_player | city: city},
          board
            |> Board.add_to_player_discard_pile(airlift_card)
            |> Board.player_arrives_in_city(role, city, :airlift)
        }
    end
  end

  def quiet_night(%Player{cards: cards} = player, board) do
    quiet_night_card = cards |> Enum.find(&(&1.action == :quiet_night))

    if quiet_night_card == nil do
       {:error, "You don't have the quiet night card"}
    else
       {:ok,
             %{player | cards: cards -- [quiet_night_card]},
             board
               |> Board.add_to_player_discard_pile(quiet_night_card)
               |> Board.enable_quiet_night()
       }
    end
  end

  def resiliant_poplulation(%Player{cards: cards} = player, city, board) do
    resiliant_population_card = cards |> Enum.find(&(&1.action == :resiliant_population))

    cond do
      resiliant_population_card == nil -> {:error, "You don't have the resiliant population card"}
      city not in board.infection_discard_pile -> {:error, "#{Cities.city_name(city)} is not in the infection discard pile"}
      true -> {:ok, %{player | cards: cards -- [resiliant_population_card]},
                      board |> Board.add_to_player_discard_pile(resiliant_population_card)
                            |> Board.remove_from_infection_discard_pile(city)}
    end
  end

  @spec forecast_peek(__MODULE__, Board) :: {:error, message :: binary} | {:ok, [atom]}
  def forecast_peek(%Player{cards: cards}, %Board{} = board) do
    forecast_card = cards |> Enum.find(&(&1.action == :forecast_card))

    if forecast_card == nil do
      {:error, "You don't have the forecast card"}
    else
      {:ok, board.infection_deck |> Enum.take(6)}
    end
  end

  def forecast_reorder(%Player{cards: cards} = player, infection_cards, %Board{} = board) do
    forecast_card = cards |> Enum.find(&(&1.action == :forecast_card))
    cond do
      forecast_card == nil ->
        {:error, "You don't have the forecast card"}
      board |> Board.forecast_cards?(infection_cards) ->
        {:ok,
        %{player | cards: cards -- [forecast_card]},
        board
          |> Board.add_to_player_discard_pile(forecast_card)
          |> Board.reorder_for_forecast(infection_cards)
        }
      true ->
        {:error, "Those are not the cards that were just peeked"}
    end
  end

end
