defmodule PandemicModel.Disease.Test do
  use ExUnit.Case
  alias PandemicModel.Disease

  test "Disease has defaults" do
    d = %Disease{state: :cured, unused_cubes: 5} 
    assert d.unused_cubes
    
  end  

end