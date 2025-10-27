defmodule GreenManTavern.DocumentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GreenManTavern.Documents` context.
  """

  @doc """
  Generate a document.
  """
  def document_fixture(attrs \\ %{}) do
    {:ok, document} =
      attrs
      |> Enum.into(%{})
      |> GreenManTavern.Documents.create_document()

    document
  end
end
