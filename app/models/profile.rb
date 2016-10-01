require 'elasticsearch/model'
require 'mongoid'
Mongoid.connect_to 'profiles'

class Profile
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
    store_in collection: 'profiles'

    # index name for keeping consistency among existing environments
    index_name "profiles-#{Rails.env}"

    field :nome, type: String, default: ""
    field :descricao, type: String, default: ""
    field :producoes_bibliograficas, type: Array, default: ""
    
    embeds_many :orientacao, store_as: :orientados
    embeds_many :projeto_pesquisa, store_as: :projeto_pesquisa
    embeds_many :area_atuacao, store_as: :areas_atuacao
    embeds_many :idioma, store_as: :idiomas
    embeds_many :premio, store_as: :premios
    embeds_many :formacao_academica, store_as: :formacoes_academicas
    embeds_many :formacao_complementar, store_as: :formacao_complementar

    def as_indexed_json(options={})
        as_json(except: [:id, :_id])
    end

end

def self.search(query)
    __elasticsearch__.search({
        query: {
            multi_match: {
                query: query,
                fields: ['titleˆ10', 'text']
            }
        },
        highlight: {
            pre_tags: ['<em>'],
            post_tags: ['</em>'],
            fields: {
            title: {},
            text: {}
            }
        }
    })
end