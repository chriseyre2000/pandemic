defmodule PandemicModel.Epidemic.Test do
  use ExUnit.Case
  alias PandemicModel.Board
  alias PandemicModel.Cities

  describe "Triggering an epidemic on an infected city" do
    setup [:an_infected_city_at_bottom_of_deck]

    test "Infected City has a disease count of 1", %{board: b, infected_city: city, infected_city_colour: colour} do
      assert 1 == Board.city_infection_count(b, city, colour)
    end  

    test "Triggering a simple epidemic leaves three disease counters on city and one on all linked cities", 
      %{board: b, infected_city: city, infected_city_colour: colour} do

      b = Board.epidemic(b)

      assert 3 == Board.city_infection_count(b, city, colour)

      assert Cities.find_by(city).links
        |> Enum.map(fn neighbour -> Board.city_infection_count(b, neighbour, colour) end)
        |> Enum.all?(&(&1 == 1))
    end
  end

  defp put_infected_city_to_bottom_of_pile(board, infected_city) do
    %Board{board | infection_deck: Enum.concat(board.infection_deck, [infected_city]), infection_discard_pile: [] }
  end  
  
  defp an_infected_city_at_bottom_of_deck(context) do
    board = Board.new() |> Board.infect()
    infected_city = List.first(board.infection_discard_pile)
    infected_city_colour = Cities.city_colour(infected_city)
    board = put_infected_city_to_bottom_of_pile(board, infected_city)

    context = Map.put(context, :board, board)
      |> Map.put(:infected_city, infected_city)
      |> Map.put(:infected_city_colour, infected_city_colour)

    {:ok, context}
  end  
end