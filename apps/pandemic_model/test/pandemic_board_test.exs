defmodule PandemicModel.Board.Test do
  use ExUnit.Case
  alias PandemicModel.{Board, Cities, Player, PlayerCard}

  test "An empty board has 48 cards in the infection deck" do
    b = Board.new()
    assert 48 == Enum.count(b.infection_deck)
  end

  test "An empty board has 0 cards in the infection disguard pile" do
    b = Board.new()
    assert Enum.empty?(b.infection_discard_pile)
  end

  test "An empty board has 0 red diseases" do
    b = Board.new()
    assert 0 == b
      |> Board.total_disease_on_board(:red)
  end

  test "State of board at start of game" do
    b = Board.new()
      |> Board.setup_board()

    assert 18 == b.cities_with_disease |> Map.values |> Enum.map(&Map.values/1) |> List.flatten |> Enum.sum
    assert 9 == b.infection_discard_pile |> Enum.count
    assert 18 == b |> Board.total_disease_on_board()
  end

  test "infect_cities moves the top two cards to discard pile" do
    board = Board.new()

    [first_card, second_card | _tail]  = board.infection_deck

    board = board
      |> Board.infect_cities()

    refute first_card in  board.infection_deck
    refute second_card in  board.infection_deck
    assert [^second_card, ^first_card] =  board.infection_discard_pile
  end

  describe "Research Station Tests" do
    setup [:simple_board]

    test "Atlanta is a research station", %{board: board} do
      assert Board.research_station?(board, :atlanta)
    end

    test "May add a research station if Atlanta is the only research station", %{board: board} do
      assert board
        |> Board.may_add_research_station?()
    end

    test "London is not a research station", %{board: board} do
      refute board
        |> Board.research_station?(:london)
    end

    test "Can make london a research station", %{board: board} do
      assert board
        |> Board.add_research_station(:london)
        |> Board.research_station?(:london)
    end

    test "Will ignore a duplicate addition of a research station", %{board: board} do
      assert board
        |> Board.add_research_station(:london)
        |> Board.add_research_station(:london)
        |> Board.research_station?(:london)
    end

    test "Will ignore a the addition of a research station beyond the sixth", %{board: board} do
      refute board
        |> Board.add_research_station(:london)
        |> Board.add_research_station(:paris)
        |> Board.add_research_station(:lima)
        |> Board.add_research_station(:milan)
        |> Board.add_research_station(:tokyo)
        |> Board.add_research_station(:new_york)
        |> Board.research_station?(:new_york)
    end

  end

  describe "Disease Board Tests" do
    setup [:simple_board]

    test "Diseases are not erradicated by default", %{board: board} do
      refute board
        |> Board.disease_erradicated?(:blue)
    end

    test "The top city in the infection discard pile has 1 disease", %{board: board, infected_city: infected_city} do
      assert 1 == board
        |> Board.city_infection_count(infected_city.id, infected_city.colour)
    end

    test "Treating the disease reduces the count", %{board: board, infected_city: infected_city} do
      assert 0 == board
        |> Board.treat_disease(infected_city.id, infected_city.colour)
        |> Board.city_infection_count(infected_city.id, infected_city.colour)
    end

    test "Curing the disease does not change the count", %{board: board, infected_city: infected_city} do
      assert 1 == board
        |> Board.cure_disease(hand_with_5_player_cards_that_are(infected_city.colour))
        |> Board.city_infection_count(infected_city.id, infected_city.colour)
    end

    test "Curing the disease changed the state from active to cured if there are disease counters left", %{board: board, infected_city: infected_city} do
      refute board
        |> Board.cure_disease(hand_with_5_player_cards_that_are(infected_city.colour))
        |> Board.disease_active?(infected_city.colour)
    end

    test "Curing a disease with no counters left erradicates it" do
      board = Board.new()
        |> Board.epidemic()
      infected_city = board.infection_deck
        |> hd()
        |> Cities.find_by()

      assert Board.disease_active?(board, infected_city.colour)

      assert 3 == Board.city_infection_count(board, infected_city.id, infected_city.colour)

      board = board
        |> Board.treat_disease(infected_city.id, infected_city.colour)
        |> Board.treat_disease(infected_city.id, infected_city.colour)
        |> Board.treat_disease(infected_city.id, infected_city.colour)

      assert 0 == Board.city_infection_count(board, infected_city.id, infected_city.colour)

      assert Board.disease_active?(board, infected_city.colour)

      board = board
        |> Board.cure_disease(hand_with_5_player_cards_that_are(infected_city.colour))

      refute Board.disease_active?(board, infected_city.colour)
      assert Board.disease_erradicated?(board, infected_city.colour)
    end

    test "Removing the last counters of a cured disease erradicates it" do
      board = Board.new()
        |> Board.epidemic()
      infected_city = board.infection_deck
        |> hd()
        |> Cities.find_by()

      assert Board.disease_active?(board, infected_city.colour)

      assert 3 == board
        |> Board.city_infection_count(infected_city.id, infected_city.colour)

      board = board
        |> Board.cure_disease(hand_with_5_player_cards_that_are(infected_city.colour))

      refute Board.disease_active?(board, infected_city.colour)
      refute Board.disease_erradicated?(board, infected_city.colour)

      board = 1..3
        |> Enum.reduce(board, fn _loop, board -> Board.treat_disease(board, infected_city.id, infected_city.colour) end)

      assert 0 == Board.city_infection_count(board, infected_city.id, infected_city.colour)

      assert Board.disease_erradicated?(board, infected_city.colour)
    end

  end

  describe "Eradicated diseases don't add cards" do
    setup [:won_game]

    test "infect city does nothing", %{won_board: board} do
      board = board
        |> Board.infect_cities()

      assert %{} == board
        |> Board.diseased_cities()
    end

    test "epidemic does nothing", %{won_board: board} do
      board = board
        |> Board.epidemic()

      assert %{} == board
        |> Board.diseased_cities()
    end
  end

  defp won_game(context) do
    board = Board.new()

    player = Player.new(:researcher, :atlanta)

    player = player
      |> Player.add_cards(hand_with_5_player_cards_that_are(:red))

    {:ok, player, board} = player
      |> Player.cure_disease(player.cards, board)

    player = player
      |> Player.add_cards(hand_with_5_player_cards_that_are(:blue))

    {:ok, player, board} = player
      |> Player.cure_disease(player.cards, board)

    player = player
      |> Player.add_cards(hand_with_5_player_cards_that_are(:black))

    {:ok, player, board} = player
      |> Player.cure_disease(player.cards, board)

    player = player
      |> Player.add_cards(hand_with_5_player_cards_that_are(:yellow))

    {:ok, _player, board} = player
      |> Player.cure_disease(player.cards, board)

    {:ok, context |> Map.put(:won_board, board)}
  end

  defp simple_board(context) do
    board = Board.new() |> Board.setup_board()
    infected_city = board.infection_discard_pile
      |> hd()
      |> Cities.find_by()
    {:ok, context |> Map.put(:board, board) |> Map.put(:infected_city, infected_city) }
  end

  defp hand_with_5_player_cards_that_are(colour) do
    Cities.all_cities
      |> Enum.filter(&(&1.colour == colour))
      |> Enum.take(5)
      |> Enum.map(&(PlayerCard.new_city(&1.id)))
  end

end
