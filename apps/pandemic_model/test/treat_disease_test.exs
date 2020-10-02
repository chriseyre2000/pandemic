defmodule PandemicModel.TreatDisease.Test do
  use ExUnit.Case
  alias PandemicModel.{Board, Cities}

  test "Treat disease" do
    b = Board.new() 
      |> Board.setup_board()
    infected_city = hd(b.infection_discard_pile)
    disease_colour = Cities.city_colour(infected_city)

    initial_disease_count = Board.city_infection_count(b, infected_city, disease_colour)

    assert 1 == initial_disease_count

    b = Board.treat_disease(b, infected_city, disease_colour)

    final_disease_count = Board.city_infection_count(b, infected_city, disease_colour)

    assert 0 == final_disease_count
  end  
end  