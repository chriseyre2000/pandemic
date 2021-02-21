defmodule PandemicModel.Cities do
  @moduledoc """
  This module defines the available cities, the colour of disease that it is associated with and
  the links to other cities.
  """
  alias PandemicModel.City

  @spec all_cities :: [City]
  @doc """
  Holds the knowledge about the cities, associated colour and links.
  """
  def all_cities do
    [
      City.new(:algiers, "Algiers", :black, [:cairo, :istanbul, :paris, :madrid], %{n: 37, e: 3}),                    # 36.7538° N, 3.0588° E
      City.new(:atlanta, "Atlanta", :blue, [:chicago, :miami, :washington], %{n: 34, w: 84}),                         # 33.7490° N, 84.3880° W
      City.new(:baghdad, "Baghdad", :black, [:riyadh, :tehran, :karachi, :cairo, :istanbul], %{n: 33, e: 44}),        # 33.3152° N, 44.3661° E
      City.new(:bangkok, "Bankok", :red, [:ho_chi_minh_city, :chennai, :kolkata, :hong_kong], %{n: 14, e: 101}),      # 13.7563° N, 100.5018° E
      City.new(:beijing, "Beijing", :red, [:shanghai, :seoul], %{n: 40, e: 116}),                                     # 39.9042° N, 116.4074° E
      City.new(:bogota, "Bogota", :yellow, [:mexico_city, :miami, :lima, :sao_paulo, :buenos_aires], %{n: 5, w: 74}), # 4.7110° N, 74.0721° W
      City.new(:buenos_aires, "Buenos Aires", :yellow, [:bogota, :sao_paulo], %{s: 35, w: 58}),                       # 34.6037° S, 58.3816° W
      City.new(:cairo, "Cairo", :black, [:riyadh, :istanbul, :baghdad, :algiers, :khartoum], %{n: 30, e: 31}),        # 30.0444° N, 31.2357° E
      City.new(:chennai, "Chennai", :black, [:bangkok, :jakarta, :mumbai, :delhi, :kolkata], %{n: 13, e: 80}),                    # 13.0827° N, 80.2707° E
      City.new(:chicago, "Chicago", :blue, [:montreal, :atlanta, :mexico_city, :los_angeles, :san_francisco], %{n: 42, w: 88}),   # 41.8781° N, 87.6298° W
      City.new(:delhi, "Delhi", :black, [:chennai, :mumbai, :karachi, :tehran, :kolkata], %{n: 29, e: 77}),                       # 28.7041° N, 77.1025° E
      City.new(:essen, "Essen", :blue, [:london, :paris, :milan, :st_petersburg], %{n: 51, e: 7}),                               # 51.4556° N, 7.0116° E
      City.new(:ho_chi_minh_city, "Ho Chi Minh City", :red, [:manila, :jakarta, :bangkok, :hong_kong], %{n: 11, e: 107}),          # 10.8231° N, 106.6297° E
      City.new(:hong_kong, "Hong Kong", :red, [:manila, :ho_chi_minh_city, :bangkok, :kolkata, :shanghai, :taipei], %{n: 25, e: 122}), # 25.0330° N, 121.5654° E
      City.new(:istanbul, "Istanbul", :black, [:cairo, :algiers, :milan, :st_petersburg, :moscow, :baghdad], %{n: 41, e: 29}), # 41.0082° N, 28.9784° E
      City.new(:johannesburg, "Johannesburg", :yellow, [:khartoum, :kinshasa], %{s: 26, e: 28}),                               # 26.2041° S, 28.0473° E
      City.new(:jakarta, "Jakarta", :red, [:ho_chi_minh_city, :sydney, :chennai], %{s: 6, e: 107}),                            # 6.2088° S, 106.8456° E
      City.new(:karachi, "Karachi", :black, [:delhi, :mumbai, :riyadh, :baghdad, :tehran], %{n: 25, e: 67}),                   # 24.8607° N, 67.0011° E
      City.new(:khartoum, "Khartoum", :yellow, [:cairo, :lagos, :kinshasa, :johannesburg], %{n: 16, e: 33}),                   # 15.5007° N, 32.5599° E
      City.new(:kinshasa, "Kinshasa", :yellow, [:johannesburg, :khartoum, :lagos], %{s: 4, e: 15}),                           # 4.4419° S, 15.2663° E
      City.new(:kolkata, "Kolkata", :black, [:hong_kong, :bangkok, :chennai, :delhi], %{n: 23, e: 88}),                        # 22.5726° N, 88.3639° E
      City.new(:lagos, "Lagos", :yellow, [:khartoum, :kinshasa, :sao_paulo], %{n: 7, e: 3}),                                 # 6.5244° N, 3.3792° E
      City.new(:lima, "Lima", :yellow, [:bogota, :mexico_city, :santiago], %{s: 12, w: 77}),                                   # 12.0464° S, 77.0428° W
      City.new(:london, "London", :blue, [:essen, :paris, :madrid, :new_york], %{ n: 52, w: 0}),                               # 51.5074° N, 0.1278° W
      City.new(:los_angeles, "Los Angeles", :yellow, [:san_francisco, :chicago, :mexico_city, :sydney], %{n: 34, w: 118}),      # 34.0522° N, 118.2437° W
      City.new(:manila, "Manila", :red, [:san_francisco, :sydney, :ho_chi_minh_city, :hong_kong, :taipei], %{n: 15, e: 121}),   # 14.5995° N, 120.9842° E
      City.new(:mexico_city, "Mexico City", :yellow, [:los_angeles, :chicago, :miami, :bogota, :lima], %{n: 19, w: 99}),        # 19.4326° N, 99.1332° W
      City.new(:miami, "Miami", :yellow, [:atlanta, :washington, :mexico_city, :bogota], %{n: 26, w: 80}),                     # 25.7617° N, 80.1918° W
      City.new(:montreal, "Montreal", :blue, [:chicago, :new_york, :washington], %{n: 56, w: 74}),                             # 45.5017° N, 73.5673° W
      City.new(:madrid, "Madrid", :blue, [:london, :paris, :algiers, :sao_paulo, :new_york], %{n: 40, w: 4}),                 # 40.4168° N, 3.7038° W
      City.new(:milan, "Milan", :blue, [:essen, :paris, :istanbul], %{n: 45, e: 9}),                                          # 45.4642° N, 9.1900° E
      City.new(:moscow, "Moscow", :black, [:st_petersburg, :istanbul, :tehran], %{n: 56, e: 38}),                              # 55.7558° N, 37.6173° E
      City.new(:mumbai, "Mumbai", :black, [:karachi, :delhi, :chennai], %{n: 19, e: 73}),                                      # 19.0760° N, 72.8777° E
      City.new(:new_york, "New York", :blue, [:london, :madrid, :washington, :montreal], %{n: 41, w: 74}),                     # 40.7128° N, 74.0060° W
      City.new(:osaka, "Osaka", :red, [:taipei, :tokyo], %{n: 35, e: 136}),                                                     # 34.6937° N, 135.5023° E
      City.new(:paris, "Paris", :blue, [:london, :madrid, :essen, :milan, :algiers], %{n: 49, e: 2}),                         # 48.8566° N, 2.3522° E
      City.new(:riyadh, "Riyadh", :black, [:cairo, :baghdad, :karachi], %{n: 25, e: 47}),                                      # 24.7136° N, 46.6753° E
      City.new(:santiago, "Santiago", :yellow, [:lima], %{s: 33, w: 70}),                                                      # 33.4489° S, 70.6693° W
      City.new(:san_francisco, "San Francisco", :blue, [:chicago, :los_angeles, :tokyo, :manila], %{n: 38, w: 122}),            # 37.7749° N, 122.4194° W
      City.new(:sao_paulo, "Sao Paulo", :yellow, [:madrid, :bogota, :buenos_aires, :lagos], %{s: 24, w: 47}),                  # 23.5505° S, 46.6333° W
      City.new(:shanghai, "Shanghai", :red, [:beijing, :seoul, :tokyo, :taipei, :hong_kong], %{n: 31, e: 121}),                 # 31.2304° N, 121.4737° E
      City.new(:seoul, "Seoul", :red, [:beijing, :shanghai, :tokyo], %{n: 38, e: 127}),                                         # 37.5665° N, 126.9780° E
      City.new(:st_petersburg, "St. Petersburg", :blue, [:essen, :moscow, :istanbul], %{n: 60, e: 30}),                        # 59.9311° N, 30.3609° E
      City.new(:sydney, "Sydney", :red, [:jakarta, :manila, :los_angeles], %{s: 34, e: 151}),                                   # 33.8688° S, 151.2093° E
      City.new(:taipei, "Taipei", :red, [:osaka, :manila, :hong_kong, :shanghai], %{n: 25, e: 122}),                            # 25.0330° N, 121.5654° E
      City.new(:tehran, "Tehran", :black, [:moscow, :baghdad, :karachi, :delhi], %{n: 36, e: 51}),                             # 35.6892° N, 51.3890° E
      City.new(:tokyo, "Tokyo", :red, [:seoul, :shanghai, :osaka, :san_francisco], %{n: 36, e: 140}),                           # 35.6762° N, 139.6503° E
      City.new(:washington, "Washington", :blue, [:atlanta, :montreal, :new_york, :miami], %{n: 39, w: 77})                   # 38.9072° N, 77.0369° W
    ]
  end

  @spec find_by(city :: atom) :: City
  @doc """
  The full city details for a given city id
  """
  def find_by(id) do
    all_cities()
    |> Enum.find(&(&1.id == id))
  end

  @spec all_keys :: [atom]
  def all_keys do
    all_cities() |> Enum.map(&Map.get(&1, :id))
  end

  @spec city_colour(city :: atom) :: :black | :blue | :red | :yellow
  def city_colour(id) do
    find_by(id).colour
  end

  @spec city_links(city :: atom) :: [atom]
  def city_links(id) do
    find_by(id).links
  end

  @spec city_name(city :: atom) :: binary
  def city_name(id) do
    find_by(id).name
  end
end
