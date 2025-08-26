defmodule Mobilizon.Service.HTTP.Utils do
  @moduledoc """
  Utils for HTTP operations
  """

  def get_tls_config do
    cacertfile =
      if is_nil(System.get_env("MOBILIZON_CA_CERT_PATH")) do
        CAStore.file_path()
      else
        System.get_env("MOBILIZON_CA_CERT_PATH")
      end

    # Check if SSL verification should be disabled (for development/testing only)
    disable_ssl_verification =
      System.get_env("MOBILIZON_DISABLE_SSL_VERIFICATION", "false") == "true"

    if disable_ssl_verification do
      [
        cacertfile: cacertfile,
        verify: :verify_none,
        verify_fun: {fn _, _, _ -> {:valid, :ok} end, []}
      ]
    else
      # Enhanced SSL configuration with TLS v1.2 support and better compatibility
      [
        cacertfile: cacertfile,
        verify: :verify_peer,
        depth: 99,
        # Support both TLS v1.2 and v1.3 for maximum compatibility
        versions: [:"tlsv1.2", :"tlsv1.3"],
        # Use secure cipher suites for TLS v1.2
        ciphers:
          :ssl.cipher_suites(:default, :"tlsv1.2") ++ :ssl.cipher_suites(:default, :"tlsv1.3"),
        # Additional options for better SSL compatibility
        secure_renegotiate: true,
        reuse_sessions: true,
        # Handle hostname verification more gracefully
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    end
  end

  @spec get_header(Enum.t(), String.t()) :: String.t() | nil
  def get_header(headers, key) do
    key = String.downcase(key)

    case List.keyfind(headers, key, 0) do
      {^key, value} -> String.downcase(value)
      nil -> nil
    end
  end

  @spec content_type_matches?(Enum.t(), String.t() | list(String.t())) :: boolean
  def content_type_matches?(headers, content_type) do
    headers
    |> get_header("Content-Type")
    |> content_type_header_matches(content_type)
  end

  @spec content_type_header_matches(String.t() | nil, Enum.t()) :: boolean
  defp content_type_header_matches(header, content_types)
  defp content_type_header_matches(nil, _content_types), do: false

  defp content_type_header_matches(header, content_type)
       when is_binary(header) and is_binary(content_type),
       do: content_type_header_matches(header, [content_type])

  defp content_type_header_matches(header, content_types)
       when is_binary(header) and is_list(content_types) do
    Enum.any?(content_types, fn content_type -> String.starts_with?(header, content_type) end)
  end
end
