defmodule QWIT.StorageTest do
  use ExUnit.Case
  alias QWIT.Storage

  doctest QWIT.Storage

  setup %{} do
    {status, _pid} = Storage.start_link()

    status
  end

  test ".put adds a value" do
    Storage.put(:hello, "world")

    assert Storage.get(:hello) == "world"
  end

  test ".delete removes a value" do
    Storage.put(:hello, "world")

    assert Storage.get(:hello) == "world"

    Storage.delete(:hello)

    assert Storage.get(:hello) == nil
  end

  test ".get retrieves a value" do
    Storage.put(:hello, "world")
    Storage.put(:goodbye, "world")

    assert Storage.get(:hello) == "world"
    assert Storage.get(:goodbye) == "world"

    Storage.put(:hello, "goodbye")

    assert Storage.get(:hello) == "goodbye"
  end
end
