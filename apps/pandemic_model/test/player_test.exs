defmodule PandemicModel.Player.Test do
  use ExUnit.Case
  alias PandemicModel.{Board, Cities, Player, PlayerCard}

  describe "Player tests" do
    setup [:player_board]

    test "Cannot drive from london to sydney", %{board: board, player: player} do
      assert {:error, "Can't drive/ferry from London to Sydney"} = player
        |> Player.drive_ferry(:sydney, board)
    end

    test "Can drive from london to paris", %{board: board, player: player} do
      assert {:ok, player, board} = player
        |> Player.drive_ferry(:paris, board)
    end

    test "Can direct fly to Syndey with the Sydney Card", %{board: board, player: player} do
      sydney_card = PlayerCard.new_city(:sydney)
      assert {:ok, player, board} = player
        |> Player.direct_flight(sydney_card, board)
    end

    test "Cannot direct flight with a :government_grant Card", %{board: board, player: player, government_grant_card: government_grant_card} do
      assert {:error, "That's an event card, you need a city card for a direct flight."} = player
        |> Player.direct_flight(government_grant_card, board)
    end

    test "Charter Flight from london to sydney using the london card will work", %{board: board, player: player, london_card: london_card} do
      assert {:ok, player, board} = player
        |> Player.charter_flight(london_card, :sydney, board)
    end

    test "Charter Flight from london to sydney using the paris card will fail", %{board: board, player: player} do
      paris_card = PlayerCard.new_city(:paris)
      assert {:error, "You are currently in London but the card was for Paris"} = player
        |> Player.charter_flight(paris_card, :sydney, board)
    end

    test "Charter flight from london to sydney using a government grant card will fail", %{board: board, player: player, government_grant_card: government_grant_card} do
      assert {:error, "That's an event card, you need a city card for a charter flight."} = player
      |> Player.charter_flight(government_grant_card, :sydney, board)
    end

    test "Cannot Shuttle Flight from london to sydney when london does not have a research station", %{board: board, player: player} do
      assert {:error, "You are in London which does not have a research station."} = player
      |> Player.shuttle_flight(:sydney, board)
    end

    test "Cannot Shuttle Flight from london to sydney when london does have a research station but sydney does not", %{board: board, player: player} do
      board = board
        |> Board.add_research_station(:london)

      assert {:error, "There is no research station at Sydney"} = player
        |> Player.shuttle_flight(:sydney, board)
    end

    test "Can shuttle flight from london to atlanta when london has research station", %{board: board, player: player} do
      board = board
        |> Board.add_research_station(:london)

      assert {:ok, player, board} = player
        |> Player.shuttle_flight(:atlanta, board)
    end

    test "Can build a research station in London", %{board: board, player: player} do
      assert {:ok, player, board} = player
        |> Player.build_a_research_station(board)
    end

    test "Cannot build a research station in Atlanta", %{board: board} do
      player = Player.new(:researcher)
      assert {:error, "There is already a research station at Atlanta"} = player
        |> Player.build_a_research_station(board)
    end

    test "There can only ever be 6 research stations", %{player: player} do
      board = Board.new()
        |> Board.add_research_station(:paris)
        |> Board.add_research_station(:milan)
        |> Board.add_research_station(:new_york)
        |> Board.add_research_station(:bogata)
        |> Board.add_research_station(:liam)

      assert {:error, "We already have 6 reasearch stations, can't build more"} = player
        |> Player.build_a_research_station(board)
    end

    test "Treat disease does not work if there is no disease to treat", %{player: player} do
      board = Board.new()
      {:error, "No disease to cure here"} = Player.treat_disease(player, :blue, board)
    end

    test "Treat disease will reduced an existing infection by 1 when it is not cured" do
      board = Board.new
        |> Board.epidemic()

      infected_city = board.infection_deck
        |> hd()
        |> Cities.find_by()

      player = Player.new(:scientist, infected_city.id)

      assert 3 == Board.city_infection_count(board, infected_city.id, infected_city.colour)

      assert {:ok, player, board} = player
        |> Player.treat_disease(infected_city.colour, board)

      assert 2 == Board.city_infection_count(board, infected_city.id, infected_city.colour)
    end

    test "Treat disease will reduced an existing infection to 0 when it is cured" do
      board = Board.new
        |> Board.epidemic()

      infected_city = board.infection_deck
        |> hd()
        |> Cities.find_by()

      player = Player.new(:scientist, infected_city.id)

      board = board
        |> Board.cure_disease([PlayerCard.new_city(infected_city.id)])

      assert 3 == Board.city_infection_count(board, infected_city.id, infected_city.colour)

      assert {:ok, player, board} = player
        |> Player.treat_disease(infected_city.colour, board)

      assert 0 == Board.city_infection_count(board, infected_city.id, infected_city.colour)
    end

    test "Two players in the same city can knowledge share a card of that city when player 1 has the card",
      %{player: player, player_two: player_two, board: board, london_card: london_card}
    do
      player = player
        |> Player.add_card(london_card)

      assert {:ok, player, player_two, board} = player
        |> Player.share_knowledge(player_two, london_card, board)

      refute london_card in player.cards
      assert london_card in player_two.cards

    end

    test "Two players in the same city can knowledge share a card of that city when player 2 has the card",
        %{player: player, player_two: player_two, board: board, london_card: london_card}
    do
      player_two = player_two
        |> Player.add_card(london_card)

      assert {:ok, player, player_two, board} = player
        |> Player.share_knowledge(player_two, london_card, board)

      assert london_card in player.cards
      refute london_card in player_two.cards
    end

    test "Two players in the same city cannot share a card that neither has",
      %{player: player, player_two: player_two, board: board, london_card: london_card}
    do
      assert {:error, "Neither of you had the card for London"} = player
        |> Player.share_knowledge(player_two, london_card, board)
    end

    test "Two players in the same city cannot share a card of another city",
      %{player: player, player_two: player_two, board: board, paris_card: paris_card}
    do
      player = player
        |> Player.add_card(paris_card)
      assert {:error, "You need to be in the same city as the card to share knowledge"} = player
        |> Player.share_knowledge(player_two, paris_card, board)
    end

    test "A player in london cannot share knowledge with a player in paris",
      %{player: player, london_card: london_card, paris_card: paris_card, board: board}
    do
      player_two = Player.new(:medic, :paris)

      player = player
        |> Player.add_card(london_card)
        |> Player.add_card(PlayerCard.new_city(:paris))

      assert {:error, "You need to be in the same city to share knowledge"} = player
        |> Player.share_knowledge(player_two, london_card, board)
      assert {:error, "You need to be in the same city to share knowledge"} = player
        |> Player.share_knowledge(player_two, paris_card, board)
    end

    test "You cannot use share knowledge with a non-city card",
      %{player: player, player_two: player_two, government_grant_card: government_grant_card, board: board }
    do
      player = player
        |> Player.add_card(government_grant_card)

      assert {:error, "That's a event card, you need a city card to share knowledge."} = player
        |> Player.share_knowledge(player_two, government_grant_card, board)
    end

    test "Can cure a disease in a research station with five cards of an active disease",
      %{player: player, board: board}
    do

      cards = hand_with_n_player_cards_that_are(5, :blue)
      player = player
        |> Player.add_cards(cards)

      board = board
        |> Board.add_research_station(player.city)

      assert board
        |> Board.disease_active?(:blue)

      assert {:ok, player, board} = player
        |> Player.cure_disease(cards, board)

      refute board
        |> Board.disease_active?(:blue)
    end

    test "Cannot cure a disease in a research station with five cards of an cured disease",
      %{player: player, board: board}
    do
      cards = hand_with_n_player_cards_that_are(5, :blue)
      player = player
        |> Player.add_cards(cards)

      board = board
        |> Board.add_research_station(player.city)

      {:ok, player, board} = player
        |> Player.cure_disease(cards, board)

      refute board
        |> Board.disease_active?(:blue)

      player = player
        |> Player.add_cards(cards)

      assert {:error, "Disease has already been cured"} = player
        |> Player.cure_disease(cards, board)
    end



    test "Cannot cure a disease in a research station with four cards plus an event card of an active disease",
      %{player: player, board: board, government_grant_card: government_grant_card }
    do

      cards = hand_with_n_player_cards_that_are(4, :blue) ++ [government_grant_card]
      player = player
        |> Player.add_cards(cards)

      board = board
        |> Board.add_research_station(player.city)

      assert board
        |> Board.disease_active?(:blue)

      assert {:error, "All the cards need to be city cards"} = player
        |> Player.cure_disease(cards, board)
    end

    test "Cannot cure a disease in a research station with only four cards of an active disease",
      %{player: player, board: board}
    do

      cards = hand_with_n_player_cards_that_are(4, :blue)
      player = player
        |> Player.add_cards(cards)

      board = board
        |> Board.add_research_station(player.city)

      assert board
        |> Board.disease_active?(:blue)

      assert {:error, "You need 5 cards and only supplied 4"} = player
        |> Player.cure_disease(cards, board)

    end

    test "Player can play goverment grant if they have the card",
      %{player: player, board: board, government_grant_card: government_grant_card}
    do
      player = player
        |> Player.add_card(government_grant_card)

      {:ok, player, board} = player
        |> Player.government_grant(:london, board)

      assert board
        |> Board.research_station?(:london)

      assert government_grant_card not in player.cards

      assert government_grant_card in board.player_discard_pile
    end

    test "Player can play airlift card on themself if they have the card",
      %{player: player, board: board, airlift_card: airlift_card}
    do
      player = player
        |> Player.add_card(airlift_card)

      {:ok, player, board} = player
        |> Player.airlift_self(:sydney, board)

      assert player.city == :sydney
      assert airlift_card not in player.cards
      assert airlift_card in board.player_discard_pile
    end

    test "Player can play airlift card on another if they have the card",
      %{player: player, player_two: player_two, board: board, airlift_card: airlift_card}
    do
      player = player
        |> Player.add_card(airlift_card)

      {:ok, player, player_two, board} = player
        |> Player.airlift_other(player_two, :sydney, board)

      assert player_two.city == :sydney
      assert player.city == :london
      assert airlift_card not in player.cards
      assert airlift_card in board.player_discard_pile
    end

    test "Player can play quiet night", %{player: player, board: board, quiet_night: quiet_night} do
      player = player
        |> Player.add_card(quiet_night)

      {:ok, player, board} = player
        |> Player.quiet_night(board)

      assert quiet_night not in player.cards
      assert quiet_night in board.player_discard_pile
      assert board.quiet_night

      board = board
        |> Board.infect_cities()

      assert %{} == board |> Board.diseased_cities()

      refute board.quiet_night
    end

    test "Player can play resilant population", %{player: player, board: board, resiliant_population: resiliant_population} do
      player = player
        |> Player.add_card(resiliant_population)

      board = board
        |> Board.infect_cities()

      city = board.infection_discard_pile |> hd()

      {:ok, player, board} = player
        |> Player.resiliant_poplulation(city, board)

      assert resiliant_population not in player.cards
      assert resiliant_population in board.player_discard_pile
      refute city in board.infection_discard_pile
      refute city in board.infection_deck
    end
  end

  def player_board(context) do
    {:ok, context
      |> Map.put(:board, Board.new())
      |> Map.put(:player, Player.new(:scientist, :london))
      |> Map.put(:player_two, Player.new(:dispatcher, :london))
      |> Map.put(:government_grant_card, PlayerCard.new_event(:government_grant))
      |> Map.put(:quiet_night, PlayerCard.new_event(:quiet_night))
      |> Map.put(:airlift_card, PlayerCard.new_event(:airlift_card))
      |> Map.put(:london_card, PlayerCard.new_city(:london))
      |> Map.put(:paris_card, PlayerCard.new_city(:paris))
      |> Map.put(:resiliant_population, PlayerCard.new_event(:resiliant_population))
    }
  end

  defp hand_with_n_player_cards_that_are(n, colour) do
    Cities.all_cities
      |> Enum.filter(&(&1.colour == colour))
      |> Enum.take(n)
      |> Enum.map(&(PlayerCard.new_city(&1.id)))
  end
end
