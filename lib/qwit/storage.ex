defmodule QWIT.Storage do
  def start_link do
    Agent.start_link(fn -> Keyword.new() end, name: name())
  end

  def put(key, value) do
    Agent.update(name(), fn x -> Keyword.put(x, key, value) end)
  end

  def delete(key) do
    Agent.update(name(), fn x -> Keyword.drop(x, [key]) end)
  end

  def get(key, default \\ nil) do
    Agent.get(name(), fn x -> Keyword.get(x, key, default) end)
  end

  defp name do
    String.to_atom("Storage." <> inspect(self()))
  end
end
