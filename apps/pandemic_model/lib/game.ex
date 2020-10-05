defmodule PandemicModel.Game do
  alias PandemicModel.{Board, Player, PlayerCard}

  defstruct ~w[board players]a

  @roles [:medic, :scientist, :researcher, :contingency_planner, :dispatcher, :operations_expert, :quarentene_specialist]

  def new(number_of_players, number_of_epidemic_cards \\ 4) when number_of_players in 2..4 do
    board = Board.new()
      |> Board.setup_board()
      |> Board.add_player_deck()

    game = %__MODULE__{board: board, players: [] }
    available_roles = @roles |> Enum.shuffle()

    game
      |> add_players(cards_per_player(number_of_players), available_roles,  number_of_players)
      |> add_epidemic_cards(number_of_epidemic_cards)
  end

  defp add_players(game, _cards_each,  _remaining_roles,  0), do: game
  defp add_players(%__MODULE__{board: board, players: players} = game, cards_each,  [role | remaining_roles],  n) do
    player_cards = board.player_deck |> Enum.take(cards_each)
    player = Player.new(role, :atlanta, player_cards)
    board = %{board | player_deck: board.player_deck |> Enum.drop(cards_each)  }
    game = %{game | board: board, players: [player | players] }
    add_players(game, cards_each, remaining_roles, n - 1)
  end

  defp cards_per_player(n) when n in 2..4, do: 6 - n

  defp add_epidemic_cards(%__MODULE__{board: %Board{ player_deck: player_deck } = board} = game, number_of_epidemic_cards) when number_of_epidemic_cards in 3..7 do
     group_size = div(Enum.count(player_deck), number_of_epidemic_cards)

     player_deck = player_deck
      |> Enum.chunk_every(group_size)
      |> Enum.map(&((&1 ++ [ PlayerCard.new_epidemic() ])
      |> Enum.shuffle() ))
      |> List.flatten

    %{game | board: %{board | player_deck: player_deck}}
  end

end
