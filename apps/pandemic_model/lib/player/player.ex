defmodule PandemicModel.Player do
@moduledoc """
This holds the structure and behaviour of the Player.
"""
  alias PandemicModel.{Board, Cities, Player, PlayerCard}
  @player_keys ~w[role city cards actions_left once_per_turn_available stored_card]a

  @enforce_keys @player_keys
  defstruct @player_keys

  @spec new(atom(), atom(), [atom()], pos_integer(), boolean) :: PandemicModel.Player
  def new(role, city \\ :atlanta, cards \\ [], actions_left \\ 4, once_per_turn_available \\ true) do
    %Player{role: role, city: city, cards: cards, actions_left: actions_left, once_per_turn_available: once_per_turn_available, stored_card: nil}
  end

  def start_of_turn(%Player{role: _role} = player) do
    %{player | actions_left: 4, once_per_turn_available: true}
  end

  @doc """
  Adds a card to the player
  """
  def add_card(%Player{} = player, %PlayerCard{} = card) do
    %{player | cards: [card | player.cards]}
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
        player
          |> set_destination(destination)
          |> decrement_actions(),
        board |> Board.player_arrives_in_city(role, destination, :drive_ferry)
      }
    else
      {:error, "Can't drive/ferry from #{ Cities.city_name(player.city)} to #{Cities.city_name(destination)}" }
    end
  end

  @doc """
  This is one of the dispatcher only actions, move another players pawn as if ones own
  """
  def drive_ferry(%Player{role: :dispatcher} = player, %Player{role: role} = moving_player, destination, board) do
    if destination in Cities.city_links(moving_player.city) do
      {
        :ok,
        player
          |> decrement_actions(),
        moving_player
          |> set_destination(destination),
        board
          |> Board.player_arrives_in_city(role, destination, :drive_ferry)
      }
    else
      {:error, "Can't drive/ferry from #{ Cities.city_name(moving_player.city)} to #{Cities.city_name(destination)}" }
    end
  end

  def direct_flight(%Player{role: role} = player, %PlayerCard{:type => :city, :city => destination} = card, board) do
    {
      :ok,
      player
        |> set_destination(destination)
        |> decrement_actions()
        |> remove_card(card),
      board
        |> Board.player_arrives_in_city(role, destination, :direct_flight)
        |> Board.add_to_player_discard_pile(card)
    }
  end

  def direct_flight(%Player{}, %PlayerCard{:type => type} = _card, _board) do
    {:error, "That's an #{type} card, you need a city card for a direct flight."}
  end

  def direct_flight(%Player{role: :dispatcher} = player, %Player{role: role} = moving_player, %PlayerCard{:type => :city, :city => destination} = card, board) do
    {
      :ok,
      player
        |> decrement_actions()
        |> remove_card(card),
      moving_player
        |> set_destination(destination),
      board
        |> Board.player_arrives_in_city(role, destination, :direct_flight)
        |> Board.add_to_player_discard_pile(card)
    }
  end

  def charter_flight(%Player{role: role} = player, %PlayerCard{:type => :city, :city => city} = card, destination, board) do
    if city == player.city do
      {
       :ok,
       player
         |> set_destination(destination)
         |> decrement_actions()
         |> remove_card(card),
       board
         |> Board.player_arrives_in_city(role, destination, :charter_flight)
         |> Board.add_to_player_discard_pile(card)
      }
    else
      {:error, "You are currently in #{ Cities.city_name(player.city)} but the card was for #{ Cities.city_name(city)}"}
    end
  end

  def charter_flight(%Player{} = _player, %PlayerCard{:type => type}, _destination, _board) do
    {:error, "That's an #{type} card, you need a city card for a charter flight."}
  end

  def charter_flight(%Player{role: :dispatcher} = player, %Player{role: role} = moving_player, %PlayerCard{:type => :city, :city => city} = card, destination, board) do
    if city == moving_player.city do
      {
       :ok,
       player
         |> decrement_actions()
         |> remove_card(card),
       moving_player
         |> set_destination(destination),
       board
         |> Board.player_arrives_in_city(role, destination, :charter_flight)
         |> Board.add_to_player_discard_pile(card)
      }
    else
      {:error, "You are currently in #{ Cities.city_name(moving_player.city)} but the card was for #{ Cities.city_name(city)}"}
    end
  end

  def shuttle_flight(%Player{role: role} = player, destination, %Board{} = board) do
    cond do
      not Board.research_station?(board, player.city) -> {:error, "You are in #{ Cities.city_name(player.city)} which does not have a research station."}
      not Board.research_station?(board, destination) -> {:error, "There is no research station at #{ Cities.city_name(destination)}"}
      true ->
        {
          :ok,
          player
            |> set_destination(destination)
            |> decrement_actions(),
          board
            |> Board.player_arrives_in_city(role, destination, :shuttle_flight)
        }
    end
  end

  def shuttle_flight(%Player{role: :dispatcher} = player, %Player{role: role} = moving_player, destination, %Board{} = board) do
    cond do
      not Board.research_station?(board, moving_player.city) -> {:error, "You are in #{ Cities.city_name(moving_player.city)} which does not have a research station."}
      not Board.research_station?(board, destination) -> {:error, "There is no research station at #{ Cities.city_name(destination)}"}
      true ->
        {
          :ok,
          player
            |> decrement_actions(),
          moving_player
            |> set_destination(destination),
          board
            |> Board.player_arrives_in_city(role, destination, :shuttle_flight)
        }
    end
  end

  def build_a_research_station(%Player{} = player, %Board{} = board) do
    cond do
      not Board.may_add_research_station?(board) -> {:error, "We already have 6 reasearch stations, can't build more"}
      Board.research_station?(board, player.city) -> {:error, "There is already a research station at #{ Cities.city_name(player.city)}"}
      true ->
        {
          :ok,
          player
            |> decrement_actions(),
          board
            |> Board.add_research_station(player.city)
        }
    end
  end

  def treat_disease(%Player{} = player, colour, board) do
    if Board.city_infection_count(board, player.city, colour) == 0 do
      {:error, "No disease to cure here"}
    else
      {
        :ok,
        player
          |> decrement_actions(),
        board
          |> Board.treat_disease(player.city, colour)
      }
    end
  end

  def share_knowledge(%Player{} = player, %Player{} = other_player, %PlayerCard{:type => :city, :city => city} = card, board ) do
    cond do
      player.city != other_player.city -> {:error, "You need to be in the same city to share knowledge"}
      invalid_city?(player, other_player, card) -> {:error, "You need to be in the same city as the card to share knowledge"}
      card in player.cards ->
        {
          :ok,
          player
            |> remove_card(card)
            |> decrement_actions(),
          other_player
            |> add_card(card),
          board
        }
      card in other_player.cards ->
        {
          :ok,
          player
            |> add_card(card)
            |> decrement_actions(),
          other_player
            |> remove_card(card),
          board
        }
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
      true ->
        {
          :ok,
          player
            |> remove_cards(cards)
            |> decrement_actions(),
          board
            |> Board.cure_disease(cards)
        }
    end
  end

  defp get_card(role, action, stored_card, cards) do
    if role == :contingency_planner and stored_card.action == action do
      stored_card
    else
      cards |> Enum.find(&(&1.action == action))
    end
  end

  def government_grant(%Player{role: role, cards: cards, stored_card: stored_card} = player, city, board) do
    government_grant_card = get_card(role, :government_grant, stored_card, cards)

    cond do
       government_grant_card == nil -> {:error, "You don't have the government grant card" }
       false == board |> Board.may_add_research_station?() -> {:error, "There are already 6 research stations"}
       board
         |> Board.research_station?(city) -> {:error, "There is already a research station there"}
       true ->
        {
          :ok,
          player
            |> remove_card(government_grant_card)
            |> remove_stored_card_if_used(government_grant_card),
          board
            |> Board.add_to_player_discard_pile(government_grant_card)
            |> Board.add_research_station(city)
        }
    end
  end

  def airlift_self(%Player{role: role, cards: cards, stored_card: stored_card} = player, city, board) do
    airlift_card = get_card(role, :airlift, stored_card, cards)

    cond do
      airlift_card == nil -> {:error, "You don't have the airlift card"}
      player.city == city -> {:error, "You are already in #{Cities.city_name(city)}"}
      true ->
        {
          :ok,
          player
            |> remove_card(airlift_card)
            |> set_destination(city)
            |> remove_stored_card_if_used(airlift_card),
          board
            |> Board.add_to_player_discard_pile(airlift_card)
            |> Board.player_arrives_in_city(role, city, :airlift)
        }
    end
  end

  def airlift_other(%Player{cards: cards, role: role, stored_card: stored_card} = player, %Player{} = travelling_player, city, %Board{} = board)  do
    airlift_card = get_card(role, :airlift, stored_card, cards)

    cond do
      airlift_card == nil -> {:error, "You don't have the airlift card"}
      travelling_player.city == city -> {:error, "#{travelling_player.role} is already in #{Cities.city_name(city)}"}
      true ->
        {
          :ok,
          player
            |> remove_card(airlift_card)
            |> remove_stored_card_if_used(airlift_card),
          %{travelling_player | city: city},
          board
            |> Board.add_to_player_discard_pile(airlift_card)
            |> Board.player_arrives_in_city(role, city, :airlift)
        }
    end
  end

  def quiet_night(%Player{cards: cards, role: role, stored_card: stored_card} = player, board) do
    quiet_night_card = get_card(role, :quiet_night, stored_card, cards)

    if quiet_night_card == nil do
       {:error, "You don't have the quiet night card"}
    else
       {
         :ok,
         player
           |> remove_card(quiet_night_card)
           |> remove_stored_card_if_used(quiet_night_card),
         board
           |> Board.add_to_player_discard_pile(quiet_night_card)
           |> Board.enable_quiet_night()
       }
    end
  end

  def resiliant_poplulation(%Player{cards: cards, role: role, stored_card: stored_card} = player, city, board) do
    resiliant_population_card = get_card(role, :resiliant_population, stored_card, cards)

    cond do
      resiliant_population_card == nil -> {:error, "You don't have the resiliant population card"}
      city not in board.infection_discard_pile -> {:error, "#{Cities.city_name(city)} is not in the infection discard pile"}
      true ->
        {
          :ok,
          player
            |> remove_card(resiliant_population_card)
            |> remove_stored_card_if_used(resiliant_population_card),
          board
            |> Board.add_to_player_discard_pile(resiliant_population_card)
            |> Board.remove_from_infection_discard_pile(city)
        }
    end
  end

  @spec forecast_peek(__MODULE__, Board) :: {:error, message :: binary} | {:ok, [atom]}
  def forecast_peek(%Player{cards: cards, role: role, stored_card: stored_card}, %Board{} = board) do
    forecast_card = get_card(role, :forecast_card, stored_card, cards)

    if forecast_card == nil do
      {:error, "You don't have the forecast card"}
    else
      {:ok, board.infection_deck |> Enum.take(6)}
    end
  end

  def forecast_reorder(%Player{cards: cards, role: role, stored_card: stored_card} = player, infection_cards, %Board{} = board) do
    forecast_card = get_card(role, :forecast_card, stored_card, cards)
    cond do
      forecast_card == nil ->
        {:error, "You don't have the forecast card"}
      board |> Board.forecast_cards?(infection_cards) ->
        {:ok,
        player
          |> remove_card(forecast_card)
          |> remove_stored_card_if_used(forecast_card),
        board
          |> Board.add_to_player_discard_pile(forecast_card)
          |> Board.reorder_for_forecast(infection_cards)
        }
      true ->
        {:error, "Those are not the cards that were just peeked"}
    end
  end

  def build_research_station(%Player{role: role, city: city} = player, %Board{} = board) do
    cond do
      role != :operations_expert -> "Only the operations expert can do this"
      Board.research_station?(board, city) -> {:error, "#{Cities.city_name(city)} already has a research station "}
      not Board.may_add_research_station?(board) -> {:error, "There are already 6 research stations"}
      true ->
      {
        :ok,
        player
          |> decrement_actions(),
        board
          |> Board.add_research_station(city)
      }
    end
  end

  @spec travel_from_research_station_to_any_city(any, PandemicModel.PlayerCard.t(), city :: atom, Board) ::
          {:error, binary} | {:ok, Player, Board}
  def travel_from_research_station_to_any_city(%Player{role: role} = player, %PlayerCard{type: :city} = card, city, %Board{} = board) do
    cond do
      role != :operations_expert -> {:error, "Only the operations expert can do this"}
      not player.once_per_turn_available -> {:error, "You have already done this this turn"}
      card not in player.cards -> {:error, "You don't have that city card"}
      true ->
        {
          :ok,
          player
            |> used_once_per_turn()
            |> decrement_actions()
            |> remove_card(card)
            |> set_destination(city),
          board
            |> Board.player_arrives_in_city(role, city, :shuttle_flight)
            |> Board.add_to_player_discard_pile(card)
        }
    end
  end

  def travel_from_research_station_to_any_city(_player, %PlayerCard{} = _card, _city, _board) do
    {:error, "You must use a city card"}
  end

  def end_turn(%Player{} = player, %Board{} = board) do
    {
      :ok,
      player
        |> used_once_per_turn()
        |> exhaust_actions(),
      board
    }
  end

  def peek_discarded_actions(%Board{} = board) do
    {
      :ok,
      board.player_discard_pile
        |> Enum.filter(&(&1.type == :action))
    }
  end

  def take_discarded_action(%Player{role: role} = player, %PlayerCard{type: :action} = card, %Board{} = board) do
    cond do
      role != :contingency_planner -> {:error, "You need to be the Contingency Planner to play this"}
      card not in board.player_discard_pile -> {:error, "That card is not in the player discard pile"}
      player.stored_card != nil -> {:error, "You already have one stored card"}
      true ->
        {
          :ok,
          %{player | stored_card: card |> PlayerCard.mark_stored() }
            |> decrement_actions(),
          board
            |> Board.remove_from_player_discard_pile(card)
        }
    end
  end

  defp used_once_per_turn(%Player{} = player) do
    %{player | once_per_turn_available: false}
  end

  defp decrement_actions(%Player{actions_left: actions_left} = player) do
    %{player | actions_left: actions_left - 1}
  end

  defp exhaust_actions(%Player{} = player) do
    %{player | actions_left: 0}
  end

  defp remove_card(%Player{cards: cards} = player, %PlayerCard{} = card) do
    %{player | cards: cards -- [card]}
  end

  defp remove_cards(%Player{cards: cards} = player, player_cards) do
    %{player | cards: cards -- player_cards}
  end

  defp set_destination(%Player{} = player, city) do
    %{player | city: city}
  end

  defp remove_stored_card_if_used(%Player{role: role, stored_card: stored_card} = player, %PlayerCard{} = player_card) do
    cond do
      role != :contingency_planner -> player
      stored_card != player_card -> player
      true -> %{player | stored_card: nil}
    end
  end

end
