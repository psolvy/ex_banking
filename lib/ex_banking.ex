defmodule ExBanking do
  @moduledoc """
  API
  """

  alias ExBanking.Users
  alias ExBanking.Wallets

  defdelegate create_user(user), to: Users
  defdelegate deposit(user, amount, currency), to: Wallets
  defdelegate withdraw(user, amount, currency), to: Wallets
  defdelegate get_balance(user, currency), to: Wallets
  defdelegate send(from_user, to_user, amount, currency), to: Wallets
end
