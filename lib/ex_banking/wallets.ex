defmodule ExBanking.Wallets do
  @moduledoc """
  wallet operations
  """

  alias ExBanking.Users
  alias ExBanking.Users.User
  alias ExBanking.Wallets.Wallet

  @queue_max_size 10

  @spec deposit(String.t(), number(), String.t()) ::
          {:ok, float()}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(username, amount, currency)
      when is_binary(username) and is_binary(currency) and is_number(amount) and amount > 0 do
    with {:ok, user} <- Users.get_user(username),
         false <- queue_is_too_long?(username) do
      update_balance(user, amount, currency)
    else
      true ->
        {:error, :too_many_requests_to_user}

      {:error, _msg} = error ->
        error
    end
  end

  def deposit(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec withdraw(String.t(), number(), String.t()) ::
          {:ok, float()}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}

  def withdraw(username, amount, currency)
      when is_binary(username) and is_binary(currency) and is_number(amount) and amount > 0 do
    with {:ok, user} <- Users.get_user(username),
         false <- queue_is_too_long?(username) do
      update_balance(user, -amount, currency)
    else
      true ->
        {:error, :too_many_requests_to_user}

      {:error, _msg} = error ->
        error
    end
  end

  def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec get_balance(String.t(), String.t()) ::
          {:ok, float()}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(username, currency) when is_binary(username) and is_binary(currency) do
    with {:ok, user} <- Users.get_user(username),
         false <- queue_is_too_long?(username) do
      balance =
        user
        |> fetch_wallet(currency)
        |> Map.fetch!(:balance)
        |> humanize_balance()

      {:ok, balance}
    else
      true ->
        {:error, :too_many_requests_to_user}

      {:error, _msg} = error ->
        error
    end
  end

  def get_balance(_user, _currency), do: {:error, :wrong_arguments}

  @spec send(String.t(), String.t(), number(), String.t()) ::
          {:ok, float(), float()}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user_username, to_user_username, amount, currency)
      when is_binary(from_user_username) and is_binary(to_user_username) and is_binary(currency) and
             is_number(amount) and amount > 0 do
    with {:sender, {:ok, from_user}} <- {:sender, Users.get_user(from_user_username)},
         {:receiver, {:ok, to_user}} <- {:receiver, Users.get_user(to_user_username)},
         {:sender, false} <- {:sender, queue_is_too_long?(from_user.username)},
         {:receiver, false} <- {:receiver, queue_is_too_long?(to_user.username)},
         {:ok, from_balance} <- update_balance(from_user, -amount, currency),
         {:ok, to_balance} <- update_balance(to_user, amount, currency) do
      {:ok, from_balance, to_balance}
    else
      {:sender, {:error, :user_does_not_exist}} -> {:error, :sender_does_not_exist}
      {:receiver, {:error, :user_does_not_exist}} -> {:error, :receiver_does_not_exist}
      {:sender, true} -> {:error, :too_many_requests_to_sender}
      {:receiver, true} -> {:error, :too_many_requests_to_receiver}
      {:error, _msg} = error -> error
    end
  end

  def send(_from_user, _to_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec update_balance(User.t(), number(), String.t()) ::
          {:ok, float()} | {:error, :not_enough_money}
  defp update_balance(user, amount, currency) do
    wallet = fetch_wallet(user, currency)
    new_balance = calculate_new_balance(amount, wallet.balance)

    if Decimal.gt?(new_balance, 0) or Decimal.eq?(new_balance, 0) do
      updated_wallet = Map.put(wallet, :balance, new_balance)
      updated_wallets = Map.put(user.wallets, currency, updated_wallet)

      user
      |> Map.put(:wallets, updated_wallets)
      |> Users.Genserver.update_user()

      {:ok, humanize_balance(updated_wallet.balance)}
    else
      {:error, :not_enough_money}
    end
  end

  @spec fetch_wallet(User.t(), String.t()) :: Wallet.t()
  defp fetch_wallet(user, currency) do
    case Map.get(user.wallets, currency) do
      nil -> %Wallet{currency: currency}
      wallet -> wallet
    end
  end

  @spec queue_is_too_long?(String.t()) :: boolean()
  defp queue_is_too_long?(username) do
    [{pid, _}] = Registry.lookup(ExBanking.Registry.Users.Registry, username)
    {:message_queue_len, queue_length} = Process.info(pid, :message_queue_len)

    queue_length > @queue_max_size
  end

  @spec calculate_new_balance(number(), Decimal.t()) :: Decimal.t()
  defp calculate_new_balance(amount, wallet_balance) when is_integer(amount),
    do: Decimal.add(amount, wallet_balance)

  defp calculate_new_balance(amount, wallet_balance) when is_float(amount),
    do: amount |> Decimal.from_float() |> Decimal.add(wallet_balance)

  @spec humanize_balance(Decimal.t()) :: float()
  defp humanize_balance(balance), do: balance |> Decimal.round(2) |> Decimal.to_float()
end
