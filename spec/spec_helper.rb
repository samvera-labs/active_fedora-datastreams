$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'equivalent-xml/rspec_matchers'
require 'active_fedora/datastreams'
require_relative 'samples/hydra-mods_article_datastream.rb'
require 'logger'

ActiveFedora::Base.logger = Logger.new(STDERR)
ActiveFedora::Base.logger.level = Logger::WARN

# This loads the Fedora and Solr config info from /config/fedora.yml
# You can load it from a different location by passing a file path as an argument.
def restore_spec_configuration
  ActiveFedora.init(fedora_config_path: File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))
end
restore_spec_configuration

require 'active_fedora/cleaner'
RSpec.configure do |config|
  # Stub out test stuff.
  config.before(:each) do
    begin
      ActiveFedora::Cleaner.clean!
    rescue Faraday::ConnectionFailed, RSolr::Error::ConnectionRefused => e
      $stderr.puts e.message
    end
  end
  config.after(:each) do
    # cleanout_fedora
  end
  config.order = :random if ENV['CI']
end

def fixture(file)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', file), 'rb')
end
