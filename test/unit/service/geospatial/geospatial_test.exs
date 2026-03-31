defmodule Mobilizon.Service.GeospatialTest do
  use Mobilizon.UnitCase

  alias Mobilizon.Service.Geospatial

  describe "get service" do
    assert Geospatial.service() === Elixir.Mobilizon.Service.Geospatial.Mock
  end
end