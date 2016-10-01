require 'elasticsearch/model'
require 'mongoid'
Mongoid.connect_to 'profiles'

class FormacaoAcademica
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    field :orientador, type: String, default: ""
    field :data_fim, type: String, default: ""
    field :outros_dados, type: Array, default: ""
    field :data_inicio, type: String, default: ""
    field :instituicao, type: String, default: ""
    field :titulo, type: String, default: ""
    
    embedded_in :profile
end