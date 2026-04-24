defmodule Mobilizon.Service.GeospatialTest do
  use Mobilizon.UnitCase

  alias Mobilizon.Service.Geospatial

  describe "get service" do
    test "returns the configured mock" do
      assert Geospatial.service() === Mobilizon.Service.Geospatial.Mock
    end
  end
end
