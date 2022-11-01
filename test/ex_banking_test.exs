defmodule ExBankingTest do
  use ExUnit.Case, async: true

  setup do
    on_exit(fn ->
      ExBanking.Users.Supervisor.terminate_all()
      # this one for give registry some time to clear trminated processes names
      Process.sleep(1)
    end)
  end

  describe "create_user/1" do
    test "with wrong arguments returns error" do
      assert {:error, :wrong_arguments} = ExBanking.create_user(123)
    end

    test "with right arguments creates user" do
      assert :ok = ExBanking.create_user("user")
    end

    test "with same name returns error" do
      assert :ok = ExBanking.create_user("user")

      assert {:error, :user_already_exists} = ExBanking.create_user("user")
    end
  end

  describe "get_balance/2" do
    test "with wrong user returns error" do
      assert {:error, :wrong_arguments} = ExBanking.get_balance(123, "$")
    end

    test "with wrong currency returns error" do
      assert {:error, :wrong_arguments} = ExBanking.get_balance("user", 321)
    end

    test "without user returns error" do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("user", "$")
    end

    test "with not existing wallet returns balance" do
      username = "user"
      :ok = ExBanking.create_user(username)

      assert {:ok, 0.0} = ExBanking.get_balance(username, "$")
    end

    test "with existing wallet returns balance" do
      username = "user"
      :ok = ExBanking.create_user(username)
      {:ok, total} = ExBanking.deposit(username, 42, "$")

      assert {:ok, ^total} = ExBanking.get_balance(username, "$")
    end
  end

  describe "deposit/3" do
    test "with wrong user returns error" do
      assert {:error, :wrong_arguments} = ExBanking.deposit(123, 42, "$")
    end

    test "with wrong amount returns error" do
      assert {:error, :wrong_arguments} = ExBanking.deposit("user", -42, "$")
    end

    test "with wrong currency returns error" do
      assert {:error, :wrong_arguments} = ExBanking.deposit("user", 42, 321)
    end

    test "without user returns error" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("user", 42, "$")
    end

    test "with right arguments makes deposit" do
      username = "user"
      :ok = ExBanking.create_user(username)

      assert {:ok, 42.0} = ExBanking.deposit(username, 42, "$")
      assert {:ok, 42.0} = ExBanking.get_balance(username, "$")
    end
  end

  describe "withdraw/3" do
    test "with wrong user returns error" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw(123, 42, "$")
    end

    test "with wrong amount returns error" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw("user", -42, "$")
    end

    test "with wrong currency returns error" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw("user", 42, 321)
    end

    test "without user returns error" do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("user", 42, "$")
    end

    test "without enough money returns error" do
      username = "user"
      :ok = ExBanking.create_user(username)

      assert {:error, :not_enough_money} = ExBanking.withdraw(username, 42, "$")
      assert {:ok, 0.0} = ExBanking.get_balance(username, "$")
    end

    test "with right arguments makes withdraw" do
      username = "user"
      :ok = ExBanking.create_user(username)
      {:ok, 42.0} = ExBanking.deposit(username, 42, "$")

      assert {:ok, 21.0} = ExBanking.withdraw(username, 21, "$")
      assert {:ok, 21.0} = ExBanking.get_balance(username, "$")
    end
  end

  describe "send/4" do
    test "with wrong from_user returns error" do
      assert {:error, :wrong_arguments} = ExBanking.send(123, "to_user", 42, "$")
    end

    test "with wrong to_user returns error" do
      assert {:error, :wrong_arguments} = ExBanking.send("from_user", 123, 42, "$")
    end

    test "with wrong amount returns error" do
      assert {:error, :wrong_arguments} = ExBanking.send("from_user", "to_user", -42, "$")
    end

    test "with wrong currency returns error" do
      assert {:error, :wrong_arguments} = ExBanking.send("from_user", "to_user", 42, 321)
    end

    test "without from_user returns error" do
      assert {:error, :sender_does_not_exist} = ExBanking.send("from_user", "to_user", 42, "$")
    end

    test "without to_user returns error" do
      from_username = "from_user"
      :ok = ExBanking.create_user(from_username)

      assert {:error, :receiver_does_not_exist} =
               ExBanking.send(from_username, "to_user", 42, "$")

      assert {:ok, 0.0} = ExBanking.get_balance(from_username, "$")
    end

    test "without enough money returns error" do
      from_username = "from_user"
      to_username = "to_user"
      :ok = ExBanking.create_user(from_username)
      :ok = ExBanking.create_user(to_username)

      assert {:error, :not_enough_money} = ExBanking.send(from_username, to_username, 42, "$")
      assert {:ok, 0.0} = ExBanking.get_balance(from_username, "$")
      assert {:ok, 0.0} = ExBanking.get_balance(to_username, "$")
    end

    test "with right arguments makes transaction" do
      from_username = "from_user"
      to_username = "to_user"
      :ok = ExBanking.create_user(from_username)
      :ok = ExBanking.create_user(to_username)
      {:ok, 42.0} = ExBanking.deposit(from_username, 42, "$")

      assert {:ok, 22.0, 20.0} = ExBanking.send(from_username, to_username, 20, "$")
      assert {:ok, 22.0} = ExBanking.get_balance(from_username, "$")
      assert {:ok, 20.0} = ExBanking.get_balance(to_username, "$")
    end
  end
end
