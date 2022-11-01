defmodule ExBanking.Users.Genserver do
  @moduledoc """
  genserver for user state
  """

  use GenServer

  alias ExBanking.Users.User

  # Client

  def start_link(username),
    do: GenServer.start_link(__MODULE__, username, name: via_tuple(username))

  def get_user(username) do
    username
    |> via_tuple()
    |> GenServer.call(:get_user)
  end

  def update_user(%User{username: username} = user) do
    username
    |> via_tuple()
    |> GenServer.cast({:update_user, user})
  end

  @spec via_tuple(String.t()) :: {:via, module(), {module(), String.t()}}
  defp via_tuple(username),
    do: {:via, Registry, {ExBanking.Registry.Users.Registry, username}}

  # Server

  @impl true
  def init(username),
    do: {:ok, %User{username: username}}

  @impl true
  def handle_call(:get_user, _from, user) do
    {:reply, user, user}
  end

  @impl true
  def handle_cast({:update_user, updated_user}, _user) do
    {:noreply, updated_user}
  end
end
