defmodule PandemicModel.Board.Test do
  use ExUnit.Case
  alias PandemicModel.Board

  test "An empty board has 48 cards in the infection deck" do
    b = Board.new()
    assert 48 == Enum.count(b.infection_deck)
  end

  test "An empty board has 0 cards in the infection disguard pile" do
    b = Board.new()
    assert 0 == Enum.count(b.infection_discard_pile)
  end

  test "An empty board has 24 red disease cubes" do
    b = Board.new()
    assert b.disease_state[:red].unused_cubes == 24
  end

  test "An empty board has not won" do
    refute Board.new() |> Board.won?
  end  

  test "An empty board has not lost" do
    refute Board.new() |> Board.lost?
  end
    
  test "State of board at start of game" do
    b = Board.new()
      |> Board.setup_board()

    assert 18 == b.cities_with_disease |> Map.values |> Enum.map(&Map.values/1) |> List.flatten |> Enum.sum
    assert 9 == b.infection_discard_pile |> Enum.count
    assert (24 * 4 - 18) == b.disease_state |> Map.values |> Enum.map(&Map.get(&1, :unused_cubes)) |> Enum.sum 
  end
  
  test "Check the add_cube_to_city function" do
    b = Board.new()
      |> Board.add_cube_to_city(:london, :blue, 1)

    assert 1 == Board.city_infection_count(b, :london, :blue)

    b = Board.add_cube_to_city(b, :london, :blue, 1)
    assert 2 == Board.city_infection_count(b, :london, :blue)

    b = Board.add_cube_to_city(b, :london, :blue, 1)
    assert 3 == Board.city_infection_count(b, :london, :blue)

    b = Board.add_cube_to_city(b, :london, :blue, 1)
    assert 3 == Board.city_infection_count(b, :london, :blue)

    b = Board.add_cube_to_city(b, :london, :red, 3)
    assert 3 == Board.city_infection_count(b, :london, :red)
  end  

  test "move to discard pile" do
    b = Board.new()

    card_to_move = hd(b.infection_deck)

    b = Board.move_top_card_to_discard_pile(b)
    assert card_to_move != hd(b.infection_deck)
    assert card_to_move == hd(b.infection_discard_pile)
    

  end  

end  