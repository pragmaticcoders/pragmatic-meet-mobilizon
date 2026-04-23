defmodule Mobilizon.Service.ActiveCampaign do
  @moduledoc """
  Synchronous ActiveCampaign API v3 integration: keep a configured mailing list in
  sync when users opt in or out of marketing (`marketing_consent`).

  Skips work when integration is disabled or misconfigured. On API errors, logs and
  returns `:ok` so registration and consent updates are not blocked.

  Configuration: `Application.get_env(:mobilizon, Mobilizon.Service.ActiveCampaign, [])`

    * `:enabled` — `true` to call the API
    * `:api_url` — account API base URL without trailing slash (e.g. `https://name.api-us1.com`)
    * `:api_key` — ActiveCampaign API token (`Api-Token` header)
    * `:list_id` — numeric list id (e.g. `7`)
  """

  import Mobilizon.Service.HTTP.Utils, only: [get_tls_config: 0]

  alias Mobilizon.Users.User

  require Logger

  @subscribed_status 1
  @unsubscribed_status 2

  @doc """
  After a successful `set_marketing_consent` mutation: subscribe or unsubscribe on AC
  and emit `Logger.info` lines prefixed with `[ActiveCampaign]` for log verification.
  """
  @spec sync_after_marketing_consent_change(User.t()) :: :ok
  def sync_after_marketing_consent_change(%User{marketing_consent: true} = user),
    do: consent_subscribe_log(user)

  def sync_after_marketing_consent_change(%User{marketing_consent: false} = user),
    do: consent_unsubscribe_log(user)

  def sync_after_marketing_consent_change(%User{}), do: :ok

  defp consent_log_ctx(%User{id: user_id}, email),
    do: "user_id=#{user_id} email=#{email} list_id=#{list_id()}"

  defp consent_subscribe_log(%User{email: email} = user) when is_binary(email) do
    email = String.trim(email)
    ctx = consent_log_ctx(user, email)

    cond do
      not enabled?() ->
        Logger.info("[ActiveCampaign] consent_subscribe skipped integration_disabled #{ctx}")

      true ->
        case validate_config() do
          {:error, reason} ->
            Logger.info(
              "[ActiveCampaign] consent_subscribe skipped misconfigured reason=#{inspect(reason)} #{ctx}"
            )

          :ok ->
            try do
              case perform_subscribe(client(), email) do
                {:ok, outcome} ->
                  Logger.info("[ActiveCampaign] consent_subscribe outcome=#{outcome} #{ctx}")

                {:error, reason} ->
                  Logger.warning("[ActiveCampaign] consent_subscribe failed #{reason} #{ctx}")
              end
            rescue
              error ->
                Logger.error(
                  "[ActiveCampaign] consent_subscribe unexpected error #{ctx} #{Exception.format(:error, error, __STACKTRACE__)}"
                )
            end
        end
    end

    :ok
  end

  defp consent_subscribe_log(_), do: :ok

  defp consent_unsubscribe_log(%User{email: email} = user) when is_binary(email) do
    email = String.trim(email)
    ctx = consent_log_ctx(user, email)

    cond do
      not enabled?() ->
        Logger.info("[ActiveCampaign] consent_unsubscribe skipped integration_disabled #{ctx}")

      true ->
        case validate_config() do
          {:error, reason} ->
            Logger.info(
              "[ActiveCampaign] consent_unsubscribe skipped misconfigured reason=#{inspect(reason)} #{ctx}"
            )

          :ok ->
            try do
              case perform_unsubscribe(client(), email) do
                {:ok, outcome} ->
                  Logger.info("[ActiveCampaign] consent_unsubscribe outcome=#{outcome} #{ctx}")

                {:error, reason} ->
                  Logger.warning("[ActiveCampaign] consent_unsubscribe failed #{reason} #{ctx}")
              end
            rescue
              error ->
                Logger.error(
                  "[ActiveCampaign] consent_unsubscribe unexpected error #{ctx} #{Exception.format(:error, error, __STACKTRACE__)}"
                )
            end
        end
    end

    :ok
  end

  defp consent_unsubscribe_log(_), do: :ok

  @spec subscribe_if_needed(User.t()) :: :ok
  def subscribe_if_needed(%User{marketing_consent: false}), do: :ok

  def subscribe_if_needed(%User{marketing_consent: true, email: email} = user)
      when is_binary(email) do
    if enabled?() do
      case validate_config() do
        :ok ->
          try do
            case perform_subscribe(client(), String.trim(email)) do
              {:ok, _} ->
                :ok

              {:error, reason} ->
                Logger.warning("[ActiveCampaign] sync failed for #{email}: #{reason}")
            end
          rescue
            error ->
              Logger.error(
                "[ActiveCampaign] unexpected error for #{inspect(user.id)}: #{Exception.format(:error, error, __STACKTRACE__)}"
              )
          end

        {:error, reason} ->
          Logger.warning("[ActiveCampaign] #{reason}")
      end
    end

    :ok
  end

  def subscribe_if_needed(%User{marketing_consent: true}), do: :ok

  @doc """
  After Mobilizon account teardown steps and before the user row is removed: set the
  contact's subscription on the **configured Pragmatic Meet list** to unsubscribed.

  Other AC lists are not inspected or modified — account deletion always proceeds and is
  never blocked by the state of external mailing lists.

  Swallows API errors (logs only) so Mobilizon deletion always proceeds.
  """
  @spec cleanup_contact_on_account_deleted(String.t() | nil) :: :ok
  def cleanup_contact_on_account_deleted(email) when is_binary(email) do
    case String.trim(email) do
      "" -> :ok
      e -> do_cleanup_contact_on_account_deleted(e)
    end
  end

  def cleanup_contact_on_account_deleted(_), do: :ok

  defp do_cleanup_contact_on_account_deleted(email) do
    cond do
      not enabled?() ->
        :ok

      match?({:error, _}, validate_config()) ->
        :ok

      true ->
        try do
          client = client()

          case find_contact_id_only(client, email) do
            {:ok, contact_id} ->
              case unsubscribe_list_membership(client, contact_id) do
                {:error, reason} ->
                  Logger.warning("[ActiveCampaign] cleanup unsubscribe failed: #{reason}")

                _ ->
                  :ok
              end

            _ ->
              :ok
          end
        rescue
          error ->
            Logger.warning(
              "[ActiveCampaign] cleanup_contact_on_account_deleted: #{Exception.format(:error, error, __STACKTRACE__)}"
            )
        end
    end

    :ok
  end

  defp enabled? do
    Application.get_env(:mobilizon, __MODULE__, [])
    |> Keyword.get(:enabled, false)
    |> truthy?()
  end

  defp truthy?(v) when v in [true, "true", "1", 1], do: true
  defp truthy?(_), do: false

  defp validate_config do
    opts = Application.get_env(:mobilizon, __MODULE__, [])
    api_url = opts[:api_url]
    api_key = opts[:api_key]

    cond do
      not is_binary(api_url) or api_url == "" ->
        {:error, "MOBILIZON_ACTIVE_CAMPAIGN_API_URL is not set"}

      not is_binary(api_key) or api_key == "" ->
        {:error, "MOBILIZON_ACTIVE_CAMPAIGN_API_KEY is not set"}

      true ->
        :ok
    end
  end

  defp list_id do
    Application.get_env(:mobilizon, __MODULE__, []) |> Keyword.get(:list_id, 7)
  end

  defp client do
    opts = Application.get_env(:mobilizon, __MODULE__, [])
    api_url = opts[:api_url] |> to_string() |> String.trim_trailing("/")
    api_key = opts[:api_key] |> to_string()

    hackney_opts =
      [recv_timeout: 25_000]
      |> Keyword.merge(ssl_options: get_tls_config())

    middleware = [
      {Tesla.Middleware.BaseUrl, api_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Api-Token", api_key}]},
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ]

    adapter = Keyword.get(opts, :adapter) || {Tesla.Adapter.Hackney, hackney_opts}

    Tesla.client(middleware, adapter)
  end

  defp perform_subscribe(client, email) do
    with {:ok, contact_id} <- find_or_create_contact_id(client, email),
         {:ok, outcome} <- ensure_on_list(client, contact_id) do
      {:ok, outcome}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp perform_unsubscribe(client, email) do
    case find_contact_id_only(client, email) do
      {:error, :no_contact} ->
        {:ok, :no_contact_in_ac}

      {:error, reason} ->
        {:error, reason}

      {:ok, contact_id} ->
        case unsubscribe_list_membership(client, contact_id) do
          {:ok, outcome} = ok ->
            maybe_delete_contact_if_no_active_lists(client, contact_id)
            ok

          other ->
            other
        end
    end
  end

  defp find_contact_id_only(client, email) do
    case Tesla.get(client, "/api/3/contacts?" <> URI.encode_query(%{"email" => email})) do
      {:ok, %Tesla.Env{status: 200, body: %{"contacts" => [%{"id" => id} | _]}}} ->
        {:ok, to_string(id)}

      {:ok, %Tesla.Env{status: 200, body: %{"contacts" => []}}} ->
        {:error, :no_contact}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "list contacts (lookup) returned #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp unsubscribe_list_membership(client, contact_id) do
    list = list_id()

    case Tesla.get(client, "/api/3/contacts/#{contact_id}/contactLists") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        lists = Map.get(body, "contactLists") || []
        do_unsubscribe_membership(client, lists, list, contact_id)

      {:ok, %Tesla.Env{status: 404, body: _}} ->
        {:ok, :not_on_list}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "contactLists returned #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp do_unsubscribe_membership(client, lists, target_list_id, contact_id) do
    target = to_string(target_list_id)

    case Enum.find(lists, fn cl -> list_id_from_membership(cl) == target end) do
      nil ->
        {:ok, :not_on_list}

      %{"id" => rel_id, "status" => status}
      when status in [@unsubscribed_status, "2", 2] ->
        {:ok, :already_unsubscribed}

      %{"id" => rel_id} ->
        case Tesla.put(client, "/api/3/contactLists/#{rel_id}", %{
               "contactList" => %{
                 "contact" => int_parse(contact_id),
                 "list" => target_list_id,
                 "status" => @unsubscribed_status
               }
             }) do
          {:ok, %Tesla.Env{status: s}} when s in [200, 201] ->
            {:ok, :unsubscribed}

          {:ok, %Tesla.Env{status: status, body: body}} ->
            {:error, "contactLists PUT unsubscribe #{status}: #{inspect(body)}"}

          {:error, reason} ->
            {:error, "HTTP #{inspect(reason)}"}
        end
    end
  end

  defp find_or_create_contact_id(client, email) do
    case Tesla.get(client, "/api/3/contacts?" <> URI.encode_query(%{"email" => email})) do
      {:ok, %Tesla.Env{status: 200, body: %{"contacts" => [%{"id" => id} | _]}}} ->
        {:ok, to_string(id)}

      {:ok, %Tesla.Env{status: 200, body: %{"contacts" => []}}} ->
        create_contact(client, email)

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "list contacts returned #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp create_contact(client, email) do
    case Tesla.post(client, "/api/3/contacts", %{"contact" => %{"email" => email}}) do
      {:ok, %Tesla.Env{status: status, body: %{"contact" => %{"id" => id}}}}
      when status in [200, 201] ->
        {:ok, to_string(id)}

      {:ok, %Tesla.Env{status: 422, body: body}} ->
        Logger.debug("[ActiveCampaign] create contact 422 (likely exists): #{inspect(body)}")

        case Tesla.get(client, "/api/3/contacts?" <> URI.encode_query(%{"email" => email})) do
          {:ok, %Tesla.Env{status: 200, body: %{"contacts" => [%{"id" => id} | _]}}} ->
            {:ok, to_string(id)}

          other ->
            {:error, "create contact 422 and refetch failed: #{inspect(body)} refetch=#{inspect(other)}"}
        end

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "create contact returned #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp ensure_on_list(client, contact_id) do
    list = list_id()

    case Tesla.get(client, "/api/3/contacts/#{contact_id}/contactLists") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        lists = Map.get(body, "contactLists") || []
        handle_existing_memberships(client, contact_id, lists, list)

      {:ok, %Tesla.Env{status: 404, body: _}} ->
        handle_existing_memberships(client, contact_id, [], list)

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "contactLists returned #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp handle_existing_memberships(client, contact_id, lists, target_list_id) do
    target = to_string(target_list_id)

    case Enum.find(lists, fn cl -> list_id_from_membership(cl) == target end) do
      nil ->
        subscribe_new_membership(client, contact_id, target_list_id)

      %{"id" => _rel_id, "status" => status} when status in [@subscribed_status, "1"] ->
        {:ok, :already_subscribed}

      %{"id" => rel_id} ->
        reactivate_membership(client, rel_id, contact_id, target_list_id)
    end
  end

  defp list_id_from_membership(cl) do
    case cl["list"] do
      %{"id" => id} -> to_string(id)
      id when not is_nil(id) -> to_string(id)
      _ -> ""
    end
  end

  defp subscribe_new_membership(client, contact_id, list_id) do
    body = %{
      "contactList" => %{
        "contact" => int_parse(contact_id),
        "list" => list_id,
        "status" => @subscribed_status
      }
    }

    case Tesla.post(client, "/api/3/contactLists", body) do
      {:ok, %Tesla.Env{status: status}} when status in [200, 201] ->
        {:ok, :subscribed}

      {:ok, %Tesla.Env{status: 422, body: body}} ->
        Logger.debug("[ActiveCampaign] contactLists 422: #{inspect(body)}")
        {:ok, :subscribed}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "contactLists POST #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp reactivate_membership(client, contact_list_rel_id, contact_id, list_id) do
    case Tesla.put(client, "/api/3/contactLists/#{contact_list_rel_id}", %{
           "contactList" => %{
             "contact" => int_parse(contact_id),
             "list" => list_id,
             "status" => @subscribed_status
           }
         }) do
      {:ok, %Tesla.Env{status: status}} when status in [200, 201] ->
        {:ok, :reactivated}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "contactLists PUT #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp int_parse(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> s
    end
  end

  defp int_parse(n) when is_integer(n), do: n

  @contact_lists_page_limit 100
  @contact_lists_max_pages 20

  defp fetch_contact_lists(client, contact_id) do
    fetch_contact_lists_page(client, contact_id, [], 0, 0)
  end

  defp fetch_contact_lists_page(_client, _contact_id, acc, _offset, page)
       when page >= @contact_lists_max_pages do
    Logger.warning(
      "[ActiveCampaign] fetch_contact_lists: reached max pages=#{@contact_lists_max_pages} contact_id=#{inspect(acc)} — truncating results"
    )

    {:ok, acc}
  end

  defp fetch_contact_lists_page(client, contact_id, acc, offset, page) do
    query =
      URI.encode_query(%{
        "limit" => @contact_lists_page_limit,
        "offset" => offset
      })

    case Tesla.get(client, "/api/3/contacts/#{contact_id}/contactLists?" <> query) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        page_items = Map.get(body, "contactLists") || []
        new_acc = acc ++ page_items

        if length(page_items) < @contact_lists_page_limit do
          {:ok, new_acc}
        else
          fetch_contact_lists_page(
            client,
            contact_id,
            new_acc,
            offset + @contact_lists_page_limit,
            page + 1
          )
        end

      {:ok, %Tesla.Env{status: 404, body: _}} ->
        {:ok, acc}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "contactLists GET #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP #{inspect(reason)}"}
    end
  end

  defp active_subscription?(cl) do
    case cl["status"] do
      s when s in [@subscribed_status, "1"] -> true
      _ -> false
    end
  end

  defp maybe_delete_contact_if_no_active_lists(client, contact_id) do
    case fetch_contact_lists(client, contact_id) do
      {:ok, lists} ->
        if not Enum.any?(lists, &active_subscription?/1) do
          delete_ac_contact(client, contact_id)
        end

      {:error, reason} ->
        Logger.debug("[ActiveCampaign] maybe_delete_contact skip: #{reason}")
    end

    :ok
  end

  defp delete_ac_contact(client, contact_id) do
    case Tesla.delete(client, "/api/3/contacts/#{contact_id}") do
      {:ok, %Tesla.Env{status: status}} when status in [200, 204] ->
        Logger.info("[ActiveCampaign] deleted AC contact id=#{contact_id}")

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.warning("[ActiveCampaign] delete AC contact failed #{status}: #{inspect(body)}")

      {:error, reason} ->
        Logger.warning("[ActiveCampaign] delete AC contact HTTP error: #{inspect(reason)}")
    end

    :ok
  end
end
