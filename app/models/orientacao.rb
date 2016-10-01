require 'elasticsearch/model'
require 'mongoid'
Mongoid.connect_to 'profiles'

class Orientacao
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    field :link, type: String, default: ""
    field :descricao, type: String, default: ""
    field :nome, type: String, default: ""
    
    embedded_in :profile
end