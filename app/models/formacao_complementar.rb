require 'elasticsearch/model'
require 'mongoid'
Mongoid.connect_to 'profiles'

class FormacaoComplementar
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    field :fim, type: String, default: ""
    field :formacao, type: String, default: ""
    field :inicio, type: String, default: ""
    
    embedded_in :profile
end