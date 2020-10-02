defmodule PandemicModel.Cities do
  alias PandemicModel.City
  def all_cities() do
    [
      City.new(:algiers, "Algiers", :black, [:cairo, :istanbul, :paris, :madrid]),
      City.new(:atlanta, "Atlanta", :blue, [:chicago, :miami, :washington]),
      City.new(:baghdad, "Baghdad", :black, [:riyadh, :tehran, :karachi, :cairo, :istanbul]),
      City.new(:bangkok, "Bankok", :red, [:ho_chi_minh_city, :chennai, :kolkata, :hong_kong]),
      City.new(:beijing, "Beijing", :red, [:shanghai, :seoul]),
      City.new(:bogota, "Bogota", :yellow, [:mexico_city, :miami, :lima, :sao_paulo, :buenos_aires]),
      City.new(:buenos_aires, "Buenos Aires", :yellow, [:bogota, :sao_paulo]),
      City.new(:cairo, "Cairo", :black, [:riyadh, :istanbul, :baghdad, :algiers, :khartoum]),
      City.new(:chennai, "Chennai", :black, [:bangkok, :jakarta, :mumbai, :delhi, :kolkata]),
      City.new(:chicago, "Chicago", :blue, [:montreal, :atlanta, :mexico_city, :los_angeles, :san_francisco]),
      City.new(:delhi, "Delhi", :black, [:chennai, :mumbai, :karachi, :tehran, :kolkata]),
      City.new(:essen, "Essen", :blue, [:london, :paris, :milan, :st_petersburg]),
      City.new(:ho_chi_minh_city, "Ho Chi Minh City", :red, [:manila, :jakarta, :bangkok, :hong_kong]),
      City.new(:hong_kong, "Hong Kong", :red, [:manila, :ho_chi_minh_city, :bangkok, :kolkata, :shanghai, :taipei]),
      City.new(:istanbul, "Istanbul", :black, [:cairo, :algiers, :milan, :st_petersburg, :moscow, :baghdad]),
      City.new(:johannesburg, "Johannesburg", :yellow, [:khartoum, :kinshasa]),
      City.new(:jakarta, "Jakarta", :red, [:ho_chi_minh_city, :sydney, :chennai]),
      City.new(:karachi, "Karachi", :black, [:delhi, :mumbai, :riyadh, :baghdad, :tehran]),
      City.new(:khartoum, "Khartoum", :yellow, [:cairo, :lagos, :kinshasa, :johannesburg]),
      City.new(:kinshasa, "Kinshasa", :yellow, [:johannesburg, :khartoum, :lagos]),
      City.new(:kolkata, "Kolkata", :black, [:hong_kong, :bangkok, :chennai, :delhi]),
      City.new(:lagos, "Lagos", :yellow, [:khartoum, :kinshasa, :sao_paulo]),
      City.new(:lima, "Lima", :yellow, [:bogota, :mexico_city, :santiago]),
      City.new(:london, "London", :blue, [:essen, :paris, :madrid, :new_york]),
      City.new(:los_angeles, "Los Angeles", :yellow, [:san_francisco, :chicago, :mexico_city, :sydney]),
      City.new(:manila, "Manila", :red, [:san_francisco, :sydney, :ho_chi_minh_city, :hong_kong, :taipei]),
      City.new(:mexico_city, "Mexico City", :yellow, [:los_angeles, :chicago, :miami, :bogota, :lima]),
      City.new(:miami, "Miami", :yellow, [:atlanta, :washington, :mexico_city, :bogota]),
      City.new(:montreal, "Montreal", :blue, [:chicago, :new_york, :washington]),
      City.new(:madrid, "Madrid", :blue, [:london, :paris, :algiers, :sao_paulo, :new_york]),
      City.new(:milan, "Milan", :blue, [:essen, :paris, :istanbul]),
      City.new(:moscow, "Moscow", :black, [:st_petersburg, :istanbul, :tehran]),
      City.new(:mumbai, "Mumbai", :black, [:karachi, :delhi, :chennai]),
      City.new(:new_york, "New York", :blue, [:london, :madrid, :washington, :montreal]),
      City.new(:osaka, "Osaka", :red, [:taipei, :tokyo]),
      City.new(:paris, "Paris", :blue, [:london, :madrid, :essen, :milan, :algiers]),
      City.new(:riyadh, "Riyadh", :black, [:cairo, :baghdad, :karachi]),
      City.new(:santiago, "Santiago", :yellow, [:lima]),
      City.new(:san_francisco, "San Francisco", :blue, [:chicago, :los_angeles, :tokyo, :manila]),
      City.new(:sao_paulo, "Sao Paulo", :yellow, [:madrid, :bogota, :buenos_aires, :lagos]),
      City.new(:shanghai, "Shanghai", :red, [:beijing, :seoul, :tokyo, :taipei, :hong_kong]),
      City.new(:seoul, "Seoul", :red, [:beijing, :shanghai, :tokyo]),
      City.new(:st_petersburg, "St. Petersburg", :blue, [:essen, :moscow, :istanbul]),
      City.new(:sydney, "Sydney", :red, [:jakarta, :manila, :los_angeles]),
      City.new(:taipei, "Taipei", :red, [:osaka, :manila, :hong_kong, :shanghai]),
      City.new(:tehran, "Tehran", :black, [:moscow, :baghdad, :karachi, :delhi]),
      City.new(:tokyo, "Tokyo", :red, [:seoul, :shanghai, :osaka, :san_francisco]),
      City.new(:washington, "Washington", :blue, [:atlanta, :montreal, :new_york, :miami]),
    ]
  end
  
  def find_by(id) do 
    all_cities() |> Enum.find(&( &1.id == id ))
  end
  
  def all_keys() do
    all_cities() |> Enum.map(&Map.get(&1, :id)) 
  end
  
  def city_colour(id) do
    find_by(id).colour
  end

  def city_links(id) do
    find_by(id).links
  end

  def city_name(id) do
    find_by(id).name
  end
end  