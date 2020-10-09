defmodule PandemicModel.Disease.Test do
  use ExUnit.Case
  alias PandemicModel.Disease

  test "Disease has defaults" do
    d = %Disease{state: :cured}
    assert d.state == :cured
  end

  test "Can cure a disease" do
    d = %Disease{state: :active}

    d = d |> Disease.cure_disease(10)

    assert d.state == :cured

    d = d |> Disease.cure_disease(0)
    assert d.state == :erradicated
  end

end
