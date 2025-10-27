defmodule GreenManTavern.AI.ClaudeClient do
  @moduledoc """
  Client for interacting with Anthropic's Claude API.

  This module handles direct API communication with Claude for
  character conversations and AI-powered interactions.
  """

  require Logger

  @api_url "https://api.anthropic.com/v1/messages"
  @model "claude-sonnet-4-20250514"
  @max_tokens 2000

  @doc """
  Send a message to Claude and get a response.

  ## Parameters
  - message: The user's message
  - system_prompt: System instructions for Claude (character personality, etc.)
  - context: Additional context from knowledge base (optional)

  ## Returns
  - {:ok, response_text} on success
  - {:error, reason} on failure
  """
  def chat(message, system_prompt, context \\ nil) do
    api_key = get_api_key()

    if is_nil(api_key) do
      {:error, "Anthropic API key not configured"}
    else
      # Build the full prompt
      full_message = build_message(message, context)

      # Make API request
      case make_request(api_key, system_prompt, full_message) do
        {:ok, response_body} ->
          extract_response(response_body)

        {:error, reason} ->
          Logger.error("Claude API error: #{inspect(reason)}")
          {:error, "Failed to get response from Claude"}
      end
    end
  end

  # Private functions

  defp get_api_key do
    # Try environment variable first, then application config
    System.get_env("ANTHROPIC_API_KEY") ||
      Application.get_env(:green_man_tavern, :anthropic_api_key)
  end

  defp build_message(message, nil), do: message

  defp build_message(message, context) do
    """
    CONTEXT FROM KNOWLEDGE BASE:
    #{context}

    USER QUESTION:
    #{message}
    """
  end

  defp make_request(api_key, system_prompt, message) do
    headers = [
      {"content-type", "application/json"},
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"}
    ]

    body = %{
      model: @model,
      max_tokens: @max_tokens,
      system: system_prompt,
      messages: [
        %{
          role: "user",
          content: message
        }
      ]
    }

    case Req.post(@api_url, json: body, headers: headers, receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: response_body}} ->
        {:ok, response_body}

      {:ok, %Req.Response{status: status_code, body: response_body}} ->
        Logger.error("Claude API returned status #{status_code}: #{inspect(response_body)}")
        {:error, "API returned status #{status_code}"}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Exception during API request: #{inspect(error)}")
      {:error, "Request failed"}
  end

  defp extract_response(response_body) do
    case response_body do
      %{"content" => [%{"text" => text} | _]} ->
        {:ok, text}

      %{"error" => %{"message" => error_message}} ->
        {:error, error_message}

      _ ->
        {:error, "Unexpected response format"}
    end
  end
end
