defmodule PandemicModel.Disease.Test do
  use ExUnit.Case
  alias PandemicModel.Disease

  test "Disease has defaults" do
    d = %Disease{state: :cured, unused_cubes: 5} 
    assert d.unused_cubes == 5
  end
  
  test "Can increment and decrement counts" do
    d = %Disease{state: :cured, unused_cubes: 5} 
    d = Disease.remove_cubes(d, 5)
    assert d.unused_cubes == 0

    d = Disease.add_cubes(d, 23)
    assert d.unused_cubes == 23

    d = Disease.cure_disease(d)
    assert d.state == :cured
    d = Disease.add_cubes(d, 1)
    assert d.unused_cubes == 24
    d = Disease.cure_disease(d)
    assert d.state == :erradicated
  end  

end