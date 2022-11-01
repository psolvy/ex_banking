defmodule ExBanking.Users do
  @moduledoc """
  dynamicly creates genserver for each user
  """

  alias ExBanking.Users
  alias ExBanking.Users.User

  @spec create_user(String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(username) when is_binary(username) do
    case Users.Supervisor.create(username) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        {:error, :user_already_exists}
    end
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @spec get_user(String.t()) ::
          {:ok, User.t()} | {:error, :user_does_not_exist}
  def get_user(username) do
    case Registry.lookup(ExBanking.Registry.Users.Registry, username) do
      [{_pid, _}] ->
        {:ok, Users.Genserver.get_user(username)}

      [] ->
        {:error, :user_does_not_exist}
    end
  end
end
