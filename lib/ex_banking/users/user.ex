defmodule ExBanking.Users.User do
  @moduledoc """
  user schema
  """

  @type t :: %__MODULE__{
          username: String.t() | nil,
          wallets: map() | nil
        }

  defstruct username: nil, wallets: %{}
end
