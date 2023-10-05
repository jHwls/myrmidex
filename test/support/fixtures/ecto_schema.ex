defmodule Myrmidex.Support.Fixtures.EctoSchema do
  @moduledoc false
  use Ecto.Schema

  schema "snapshot" do
    field :open_int, :integer
    field :volume, :integer
    field :price, :float, default: 1.0
    field :prev_close, :float
    field :extra_id, Ecto.UUID, autogenerate: true
    timestamps(updated_at: false, type: :utc_datetime_usec)

    belongs_to :symbol, __MODULE__.Parent
    has_one :contract, __MODULE__.Child
    has_many :trades, __MODULE__.Child
  end

  defmodule Parent do
    @moduledoc false
    use Ecto.Schema
    alias Myrmidex.Support.Fixtures.EctoSchema

    schema "parent" do
      field :symbol, :string
      belongs_to :snapshot, EctoSchema
    end
  end

  defmodule Child do
    @moduledoc false
    use Ecto.Schema
    alias Myrmidex.Support.Fixtures.EctoSchema

    schema "contract" do
      field :symbol, :string
      belongs_to :snapshot, EctoSchema
    end
  end

  defmodule GeneratorSchema do
    @moduledoc false
    use Myrmidex.GeneratorSchema
    alias Myrmidex.GeneratorSchemas.Default, as: DefaultSchema

    def cast({:price, _type}, _opts) do
      SD.float(min: 1, max: 500)
    end

    def cast({_field, :time}, _opts) do
      SD.repeatedly(&Time.utc_now/0)
    end

    generator_schema_fallback(DefaultSchema)
  end
end

defmodule Myrmidex.Support.Fixtures.EmbeddedSchema do
  @moduledoc false
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :date, :date
    field :time, :time
    field :preferred_time, :utc_datetime
    field :valid?, :boolean
    field :preference, Ecto.Enum, values: [:"🎃"]

    embeds_many :checkboxes, __MODULE__.Child
  end

  defmodule Child do
    @moduledoc false
    use Ecto.Schema

    embedded_schema do
      field :checked?, :boolean
    end
  end
end
