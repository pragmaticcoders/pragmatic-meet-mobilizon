# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.FormatterTest do
  alias Mobilizon.Service.Formatter
  use Mobilizon.DataCase

  import Mobilizon.Factory

  describe "add_user_links with database" do
    test "gives a replacement for user links, using local nicknames in user links text" do
      text = "@gsimg According to @archa_eme_, that is @daggsy. Also hello @archaeme@archae.me"
      gsimg = insert(:actor, preferred_username: "gsimg")

      archaeme =
        insert(:actor, preferred_username: "archa_eme_", url: "https://archeme/@archa_eme_")

      archaeme_remote = insert(:actor, preferred_username: "archaeme", domain: "archae.me")

      {text, mentions, []} = Formatter.linkify(text)

      assert length(mentions) == 3

      expected_text =
        "<span class=\"h-card mention\" data-user=\"#{gsimg.id}\">@<span>gsimg</span></span> According to <span class=\"h-card mention\" data-user=\"#{archaeme.id}\">@<span>archa_eme_</span></span>, that is @daggsy. Also hello <span class=\"h-card mention\" data-user=\"#{archaeme_remote.id}\">@<span>archaeme</span></span>"

      assert expected_text == text
    end

    test "gives a replacement for single-character local nicknames" do
      text = "@o hi"
      o = insert(:actor, preferred_username: "o")

      {text, mentions, []} = Formatter.linkify(text)

      assert length(mentions) == 1

      expected_text =
        "<span class=\"h-card mention\" data-user=\"#{o.id}\">@<span>o</span></span> hi"

      assert expected_text == text
    end

    test "does not give a replacement for single-character local nicknames who don't exist" do
      text = "@a hi"

      expected_text = "@a hi"
      assert {^expected_text, [] = _mentions, [] = _tags} = Formatter.linkify(text)
    end
  end

  test "it can parse mentions and return the relevant users" do
    text =
      "@@gsimg According to @archaeme, that is @daggsy. Also hello @archaeme@archae.me and @o and @@@jimm"

    o = insert(:actor, preferred_username: "o")
    # jimm = insert(:actor, preferred_username: "jimm")
    # gsimg = insert(:actor, preferred_username: "gsimg")
    archaeme = insert(:actor, preferred_username: "archaeme")
    archaeme_remote = insert(:actor, preferred_username: "archaeme", domain: "archae.me")

    expected_mentions = [
      {"@archaeme", archaeme.id},
      {"@archaeme@archae.me", archaeme_remote.id},
      # TODO: Debug me
      # {"@gsimg", gsimg.id},
      # {"@jimm", jimm.id},
      {"@o", o.id}
    ]

    {_text, mentions, []} = Formatter.linkify(text)

    assert expected_mentions ==
             Enum.map(mentions, fn {username, actor} -> {username, actor.id} end)
  end
end
