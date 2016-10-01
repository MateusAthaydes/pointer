require 'elasticsearch/model'
require 'mongoid'
Mongoid.connect_to 'profiles'

class Premio
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    field :ano, type: String, default: ""
    field :premio, type: String, default: ""
    
    embedded_in :profile
end