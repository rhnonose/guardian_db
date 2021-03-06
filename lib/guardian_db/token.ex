defmodule GuardianDb.Token do
  @moduledoc """
  A very simple model for storing tokens generated by guardian.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias GuardianDb.Token

  config = Application.get_env(:guardian_db, GuardianDb, [])

  @primary_key {:jti, :string, autogenerate: false}
  @schema_name Keyword.get(config, :schema_name, "guardian_tokens")
  @schema_prefix Keyword.get(config, :prefix)

  @allowed_fields ~w(jti typ aud iss sub exp jwt claims)a

  schema @schema_name do
    field(:typ, :string)
    field(:aud, :string)
    field(:iss, :string)
    field(:sub, :string)
    field(:exp, :integer)
    field(:jwt, :string)
    field(:claims, :map)

    timestamps()
  end

  @doc """
  Find one token by matching jti and aud
  """
  def find_by_claims(claims) do
    jti = Map.get(claims, "jti")
    aud = Map.get(claims, "aud")
    GuardianDb.repo().get_by(Token, jti: jti, aud: aud)
  end

  @doc """
  Create a new new token based on the JWT and decoded claims
  """
  def create!(claims, jwt) do
    prepared_claims =
      claims
      |> Map.put("jwt", jwt)
      |> Map.put("claims", claims)

    %Token{}
    |> cast(prepared_claims, @allowed_fields)
    |> GuardianDb.repo().insert()
  end

  @doc """
  Purge any tokens that are expired. This should be done periodically to keep your DB table clean of clutter
  """
  def purge_expired_tokens! do
    timestamp = Guardian.timestamp()
    query = from(token in Token, where: token.exp < ^timestamp)

    GuardianDb.repo().delete_all(query)
  end
end
