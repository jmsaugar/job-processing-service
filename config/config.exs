import Config

# Let the OS choose a free port during tests.
config :job_processing_service, :port, if(config_env() == :test, do: 0, else: 4000)
