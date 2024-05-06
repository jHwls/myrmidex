# Used only to speed up local tests for the library—will ignored by your
# application.

import Config

config :stream_data, max_runs: if(System.get_env("CI"), do: 500, else: 50)
