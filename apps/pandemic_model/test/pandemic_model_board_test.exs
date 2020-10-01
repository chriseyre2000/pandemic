defmodule PandemicModel.Board.Test do
  use ExUnit.Case
  alias PandemicModel.Board
  alias PandemicModel.Cities

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
  
  test "First infection has correct counts" do
    b = Board.new() |> Board.infect(3)
    [infected_city|_] = b.infection_discard_pile
    disease_colour = Cities.city_colour(infected_city) 
    assert Board.city_infection_count(b, infected_city, disease_colour) == 3
    assert Board.get_remaining_cubes_for_disease(b, disease_colour) == 21 
  end
  
  test "State of board at start of game" do
    b = Board.new()
      |> Board.setup_board()

    assert 18 == b.cities_with_disease |> Map.values |> Enum.map(&Map.values/1) |> List.flatten |> Enum.sum
    assert 9 == b.infection_discard_pile |> Enum.count
    assert (24 * 4 - 18) == b.disease_state |> Map.values |> Enum.map(&Map.get(&1, :unused_cubes)) |> Enum.sum 
  end  


end  