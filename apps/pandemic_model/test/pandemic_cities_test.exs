defmodule PandemicModel.Cities.Test do
  use ExUnit.Case
  alias PandemicModel.{Cities, City}

  test "We we always have paris" do
    assert "Paris" == Cities.find_by(:paris).name
    assert "Paris" == Cities.city_name(:paris)
  end

  test "all roads go via paris" do
    assert  [:london, :madrid, :essen, :milan, :algiers] == Cities.city_links(:paris)
  end

  test "We have 48 Cities" do
    assert 48 == Cities.all_cities() |> Enum.count()
  end

  test "Paris is blue" do
    assert :blue == Cities.city_colour(:paris)
  end

  test "Can make a new city" do
    c = City.new(:mancester, "Manchester", :blue, [:london])
    assert c ==  %City{colour: :blue, id: :mancester, links: [:london], name: "Manchester"}
  end

  test "All city links go to a known city" do
    c = Cities.all_cities()
    linked_to = c
      |> Enum.map(&(&1.links))
      |> List.flatten
      |> Enum.sort |> Enum.uniq
    city_ids = c
      |> Enum.map(&(&1.id))

    assert linked_to -- city_ids == []
  end

  test "City id's are unique" do
    c = Cities.all_cities()
    city_ids = c
      |> Enum.map(&(&1.id))

    assert city_ids == Enum.uniq(city_ids)
  end

  test "City name are unique" do
    c = Cities.all_cities()
    city_names = c
      |> Enum.map(&(&1.name))

    assert city_names == Enum.uniq(city_names)
  end

  test "City does not link to itself" do
    assert [] == for c <- Cities.all_cities(), c.id in c.links, do: c.name
  end

  test "All links are reversable" do
    c = Cities.all_cities()
    assert [] == for i <- c, j <- c, j.id in i.links, i.id not in j.links, do: {i.id, j.id}
  end

end
