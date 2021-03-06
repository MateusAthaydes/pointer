require 'elasticsearch/model'
require 'mongoid'
Mongoid.connect_to 'profiles'

class Idioma
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    field :nivel, type: String, default: ""
    field :idioma, type: String, default: ""

    embedded_in :profile
end