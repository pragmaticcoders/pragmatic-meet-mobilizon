# Portions of this file are derived from Pleroma:
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Upload.Filter.AnonymizeFilenameTest do
  use Mobilizon.UnitCase
  alias Mobilizon.Web.Upload.Filter.AnonymizeFilename

  describe "filter/1" do
    test "anonymizes the filename" do
      upload = %Mobilizon.Web.Upload{
        name: "an image.jpg",
        content_type: "image/jpeg",
        path: Path.absname("test/fixtures/image.jpg"),
        tempfile: Path.absname("test/fixtures/image.jpg")
      }

      {:ok, :filtered, upload} = AnonymizeFilename.filter(upload)
      assert upload.name != "an image.jpg"
      assert String.ends_with?(upload.name, ".jpg")
    end

    test "anonymizes the filename with path preserving extension" do
      upload = %Mobilizon.Web.Upload{
        name: "my_image.png",
        content_type: "image/png",
        path: Path.absname("test/fixtures/image.jpg"),
        tempfile: Path.absname("test/fixtures/image.jpg")
      }

      {:ok, :filtered, upload} = AnonymizeFilename.filter(upload)
      assert String.ends_with?(upload.name, ".png")
    end
  end
end