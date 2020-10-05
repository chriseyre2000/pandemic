defmodule PandemicModel.Game.Test do
  use ExUnit.Case
  alias PandemicModel.Game

  test "A 2 player game has two players each with 4 cards" do
    game = Game.new(2)
    assert 2 == game.players |> Enum.count()
    assert Enum.all?(game.players, &( 4 == &1.cards |> Enum.count() ))
  end

  test "A 3 player game has three players each with 3 cards" do
    game = Game.new(3)
    assert 3 == game.players |> Enum.count()
    assert Enum.all?(game.players, &( 3 == &1.cards |> Enum.count() ))
  end

  test "A 4 player game had four players each with 2 cards" do
    game = Game.new(4)
    assert 4 == game.players |> Enum.count()
    assert Enum.all?(game.players, &( 2 == &1.cards |> Enum.count() ))
  end

  test "A 2 player four epidemic game has 1 epidemic card in the first 11 cards" do
    game = Game.new(2, 4)
    assert 1 == game.board.player_deck
      |> Enum.take(11)
      |> Enum.filter( &( &1.type == :epidemic ))
      |> Enum.count()
  end

end
