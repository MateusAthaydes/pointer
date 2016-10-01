require 'elasticsearch/model'
require 'mongoid'
Mongoid.connect_to 'profiles'

class AreaAtuacao
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    field :especialidade, type: String, default: ""
    field :sub_area, type: String, default: ""
    field :grande_area, type: String, default: ""
    field :area, type: String, default:""
    
    embedded_in :profile
end