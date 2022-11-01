defmodule ExBanking.Wallets.Wallet do
  @moduledoc """
  wallet schema
  """

  @type t :: %__MODULE__{
          currency: String.t() | nil,
          balance: Decimal.t() | nil
        }

  defstruct currency: nil, balance: Decimal.new(0)
end
