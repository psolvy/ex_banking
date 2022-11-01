defmodule ExBanking.Users.Supervisor do
  @moduledoc """
  dynamic supervisor for ExBanking.Users.Genserver
  """

  use DynamicSupervisor

  def create(username),
    do: DynamicSupervisor.start_child(__MODULE__, {ExBanking.Users.Genserver, username})

  def terminate_all() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> DynamicSupervisor.terminate_child(__MODULE__, pid) end)
  end

  @impl true
  def init(_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_link(arg),
    do: DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
end
