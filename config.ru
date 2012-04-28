$:.unshift(__FILE__, ".")

require 'bucket'

use Rack::ShowExceptions

run Sinatra::Application