defmodule Mobilizon.Service.ActiveCampaignTest do
  use Mobilizon.DataCase, async: false

  import ExUnit.CaptureLog

  alias Mobilizon.Service.ActiveCampaign
  alias Mobilizon.Users.User

  setup do
    previous = Application.get_env(:mobilizon, ActiveCampaign)

    on_exit(fn ->
      if previous do
        Application.put_env(:mobilizon, ActiveCampaign, previous)
      else
        Application.delete_env(:mobilizon, ActiveCampaign)
      end
    end)

    :ok
  end

  test "subscribe_if_needed is a no-op when integration disabled" do
    Application.put_env(:mobilizon, ActiveCampaign,
      enabled: false,
      api_url: "https://example.api-us1.com",
      api_key: "secret",
      list_id: 6
    )

    user = %User{email: "newsletter@example.com", marketing_consent: true}
    assert :ok == ActiveCampaign.subscribe_if_needed(user)
  end

  test "subscribe_if_needed skips when marketing_consent is false" do
    Application.put_env(:mobilizon, ActiveCampaign,
      enabled: true,
      api_url: "https://example.api-us1.com",
      api_key: "secret",
      list_id: 6
    )

    user = %User{email: "holdout@example.com", marketing_consent: false}
    assert :ok == ActiveCampaign.subscribe_if_needed(user)
  end

  test "subscribe_if_needed returns :ok when enabled but API URL missing" do
    Application.put_env(:mobilizon, ActiveCampaign,
      enabled: true,
      api_url: nil,
      api_key: "secret",
      list_id: 6
    )

    user = %User{email: "misconfig@example.com", marketing_consent: true}
    assert :ok == ActiveCampaign.subscribe_if_needed(user)
  end

  test "sync_after_marketing_consent_change logs subscribe skip when integration disabled" do
    Application.put_env(:mobilizon, ActiveCampaign,
      enabled: false,
      api_url: "https://example.api-us1.com",
      api_key: "secret",
      list_id: 6
    )

    user = %User{id: 42, email: "opt-in@example.com", marketing_consent: true}

    log =
      capture_log(fn ->
        assert :ok == ActiveCampaign.sync_after_marketing_consent_change(user)
      end)

    assert log =~ "[ActiveCampaign] consent_subscribe skipped integration_disabled"
    assert log =~ "user_id=42"
  end

  test "sync_after_marketing_consent_change logs unsubscribe skip when integration disabled" do
    Application.put_env(:mobilizon, ActiveCampaign,
      enabled: false,
      api_url: "https://example.api-us1.com",
      api_key: "secret",
      list_id: 6
    )

    user = %User{id: 43, email: "opt-out@example.com", marketing_consent: false}

    log =
      capture_log(fn ->
        assert :ok == ActiveCampaign.sync_after_marketing_consent_change(user)
      end)

    assert log =~ "[ActiveCampaign] consent_unsubscribe skipped integration_disabled"
    assert log =~ "user_id=43"
  end
end
