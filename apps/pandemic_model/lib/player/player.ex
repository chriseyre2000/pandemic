defmodule PandemicModel.Player do
  alias PandemicModel.{Board, Cities, PlayerCard, Player}
  @player_keys ~w[role city cards]a

  @enforce_keys @player_keys
  defstruct @player_keys

  def new(role, city \\ :atlanta, cards \\ []) do
    %__MODULE__{role: role, city: city, cards: cards}
  end

  @doc """
  Adds a card to the player
  """
  def add_card(%__MODULE__{} = player, %PlayerCard{} = card) do
    %{player | cards: [card| player.cards]}
  end

  def add_cards(%__MODULE__{} = player, []) do
    player
  end

  def add_cards(%__MODULE__{} = player, [card | remaining_cards]) do
    player
      |> Player.add_card(card)
      |> Player.add_cards(remaining_cards)
  end

  def drive_ferry(%__MODULE__{} = player, destination, board) do
    if destination in Cities.city_links(player.city) do
      {:ok, %{player | city: destination}, board}
    else
      {:error, "Can't drive/ferry from #{ Cities.city_name(player.city)} to #{Cities.city_name(destination)}" }
    end
  end

  def direct_flight(%__MODULE__{} = player, %PlayerCard{:type => :city, :city => destination}, board) do
    {:ok, %{player | city: destination}, board}
  end

  def direct_flight(%__MODULE__{} = _player, %PlayerCard{:type => type} = _card, _board) do
    {:error, "That's an #{type} card, you need a city card for a direct flight."}
  end

  def charter_flight(%__MODULE__{} = player, %PlayerCard{:type => :city, :city => city}, destination_city, board) do
    if city == player.city do
      {:ok, %{player | city: destination_city}, board}
    else
      {:error, "You are currently in #{ Cities.city_name(player.city)} but the card was for #{ Cities.city_name(city)}"}
    end
  end

  def charter_flight(%__MODULE__{} = _player, %PlayerCard{:type => type}, _destination_city, _board) do
    {:error, "That's an #{type} card, you need a city card for a charter flight."}
  end

  def shuttle_flight(%__MODULE__{} = player, destination, %Board{} = board) do
    cond do
      not Board.research_station?(board, player.city) -> {:error, "You are in #{ Cities.city_name(player.city)} which does not have a research station."}
      not Board.research_station?(board, destination) -> {:error, "There is no research station at #{ Cities.city_name(destination)}"}
      true -> {:ok, %{player | city: destination}, board}
    end
  end

  def build_a_research_station(%__MODULE__{} = player, %Board{} = board) do
    cond do
      not Board.may_add_research_station?(board) -> {:error, "We already have 6 reasearch stations, can't build more"}
      Board.research_station?(board, player.city) -> {:error, "There is already a research station at #{ Cities.city_name(player.city)}"}
      true -> {:ok, player, Board.add_research_station(board, player.city)}
    end
  end

  def treat_disease(%__MODULE__{} = player, colour, board) do
    cond do
      Board.city_infection_count(board, player.city, colour) == 0 -> {:error, "No disease to cure here"}
      true -> {:ok, player, Board.treat_disease(board, player.city, colour)}
    end
  end

  def share_knowledge(%__MODULE__{} = player, %__MODULE__{} = other_player, %PlayerCard{:type => :city, :city => city} = card, board ) do
    cond do
      player.city != other_player.city -> {:error, "You need to be in the same city to share knowledge"}
      player.city != city -> {:error, "You need to be in the same city as the card to share knowledge"}
      card in player.cards -> {:ok,
                                %{player | cards: player.cards -- [card]},
                                %{ other_player | cards: other_player.cards ++ [card] },
                                board}
      card in other_player.cards -> {:ok, %{player | cards: player.cards ++ [card] }, %{ other_player | cards: other_player.cards -- [card] }, board}
      true -> {:error, "Neither of you had the card for #{Cities.city_name(city)}"}
    end
  end

  def share_knowledge(%__MODULE__{} =_player, %__MODULE__{} = _otherPlayer, %PlayerCard{:type => type}, _board) do
    {:error, "That's a #{type} card, you need a city card to share knowledge."}
  end

  def cure_disease(%Player{}=player, cards, %Board{} = board) do
    cond do
      Enum.count(cards) != 5 -> {:error, "You need 5 cards and only supplied #{Enum.count(cards)}"}
      cards |> Enum.any?(&(&1.type != :city)) -> {:error, "All the cards need to be city cards"}
      cards -- player.cards != [] -> {:error, "You don't have those cards"}
      cards |> Enum.map(&(&1.city)) |> Enum.map(&Cities.city_colour/1) |> Enum.frequencies() |> Map.values != [5] -> {:error, "You don't have 5 cards of the same colour"}
      not Board.disease_active?(board, cards |> hd() |> Map.get(:city) |> Cities.city_colour()) -> {:error, "Disease has already been cured"}
      true -> {:ok, %{player | cards: player.cards -- cards }, Board.cure_disease(board, cards) }
    end
  end

  # PlayerCard.new_event(:quiet_night),
  # PlayerCard.new_event(:forecast),
  # PlayerCard.new_event(:resiliant_population),

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

  def airlift_self(%Player{cards: cards} = player, city, board) do
    airlift_card = cards |> Enum.find(&(&1.action == :airlift_card))

    cond do
      airlift_card == nil -> {:error, "You don't have the airlift card"}
      player.city == city -> {:error, "You are already in #{Cities.city_name(city)}"}
      true -> {:ok, %{player | city: city, cards: cards -- [airlift_card]}, board |> Board.add_to_player_discard_pile(airlift_card)}
    end
  end

  def airlift_other(%Player{cards: cards}=player, %Player{}=travelling_player, city, board) when player != travelling_player  do
    airlift_card = cards |> Enum.find(&(&1.action == :airlift_card))

    cond do
      airlift_card == nil -> {:error, "You don't have the airlift card"}
      travelling_player.city == city -> {:error, "#{travelling_player.role} is already in #{Cities.city_name(city)}"}
      true -> {:ok, %{player | cards: cards -- [airlift_card]}, %{travelling_player | city: city},  board |> Board.add_to_player_discard_pile(airlift_card)}
    end
  end


end
