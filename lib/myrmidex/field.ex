defmodule Myrmidex.Field do
  @moduledoc """
  A tuple representing a struct or map field with type information and, depending
  on the source, a represenative term.

  GeneratorSchemas are passed field tuples, and cast them to generators.

  """
  @type t :: {atom(), Ecto.Type.t(), term()} | {atom() | String.t(), term()}

  defguardp is_valid_field_name(field_tuple)
            when is_atom(elem(field_tuple, 0)) or is_binary(elem(field_tuple, 0))

  @doc false
  defguard is_field(field_tuple)
           when is_tuple(field_tuple) and tuple_size(field_tuple) in [2, 3] and
                  is_valid_field_name(field_tuple)

  @doc false
  def name({name, _type, _term}), do: name
  def name({name, _type}), do: name

  @doc false
  def term({_name, _type, term}), do: term
  def term({_name, term}), do: term
end
