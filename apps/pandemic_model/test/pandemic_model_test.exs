defmodule PandemicModelTest do
  use ExUnit.Case
  doctest PandemicModel
  alias PandemicModel.Cities

  test "All city links go to a known city" do
    c = Cities.all_cities()
    linked_to = c |> Enum.map( &( &1.links )) |> List.flatten |> Enum.sort |> Enum.uniq
    city_names = c |> Enum.map( &( &1.id ))

    assert linked_to -- city_names == []
  end

  test "City id's are unique" do
    c = Cities.all_cities()
    city_ids = c |> Enum.map( &( &1.id ))

    assert city_ids == Enum.uniq(city_ids)
  end

  test "City name are unique" do
    c = Cities.all_cities()
    city_names = c |> Enum.map( &( &1.name ))

    assert city_names == Enum.uniq(city_names)
  end
  
  test "find_by id" do
    assert Cities.find_by(:paris).name == "Paris"
  end
  
  test "City does not link to itself" do
    assert [] == for c <- Cities.all_cities(), c.id in c.links, do: c.name 
  end
  
  test "All links are reversable" do
    c = Cities.all_cities()
    assert [] == for i <- c, j <- c, j.id in i.links, i.id not in j.links, do: {i.id, j.id}
  end  
end
