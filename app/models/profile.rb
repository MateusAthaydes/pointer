require 'elasticsearch/model'
require 'mongoid'
require 'Date'
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
    field :producoes_bibliograficas, type: Array, default: []
    field :ranking_pessoal, type: Float, default: 0.0
    
    embeds_many :orientacao, store_as: :orientados
    embeds_many :projeto_pesquisa, store_as: :projeto_pesquisa
    embeds_many :area_atuacao, store_as: :areas_atuacao
    embeds_many :idioma, store_as: :idiomas
    embeds_many :premio, store_as: :premios
    embeds_many :formacao_academica, store_as: :formacao_academicas
    embeds_many :formacao_complementar, store_as: :formacao_complementar

    def as_indexed_json(options={})
        as_json(except: [:id, :_id])
    end

    set_callback(:save, :before) do |document|
        personal_ranking_value = document.calculate_personal_ranking
        document.ranking_pessoal = personal_ranking_value
    end

    def calculate_personal_ranking
        # O ranking pessoal é dado por:
        # Média ponderada de:
        # (AR) Tempo em atividade recente - peso 3
        # (XP) Tempo de experiência - peso 1
        # (NA) Número de artigos - peso 4
        # (GR) Grau de formação - peso 2
        atividade_recente = self.get_atividade_recente
        experiencia = self.get_tempo_experiencia
        numero_artigos = self.get_numero_artigos
        grau_formacao = self.get_grau_formacao

        return (atividade_recente * 3 + experiencia * 1 + numero_artigos * 4 + grau_formacao * 2) / 10
    end

    protected
    def get_atividade_recente
        this_year = Date.today.year
        three_years_ago = this_year - 3
        actual_publication_count = 0
        self.producoes_bibliograficas.each do |producao|
            # Este regex pega o ano de publicação da publicação corrente - (serão sempre 4 digitos seguidos de ponto (e.g. ', 2007.'))
            pub_year = producao[/, \b[0-9]{4}\b\./]
            if pub_year
                pub_year = pub_year[/[0-9]{4}/].to_i
                if pub_year >= three_years_ago and pub_year <= this_year
                    actual_publication_count += 1
                end
            end
        end
        return actual_publication_count
    end

    protected
    def get_tempo_experiencia
        this_year = Date.today.year
        experience_years_count = 0
        last_experience_year = this_year
        self.formacao_academica.each do |formacao|
            if formacao.data_fim != "Atual"
                if formacao.data_fim.to_i < last_experience_year.to_i
                    last_experiece_year = formacao.data_fim.to_i
                end
            else
                if formacao.data_inicio.to_i < last_experience_year.to_i
                    last_experience_year = formacao.data_inicio.to_i
                end
            end
        end
        return this_year - last_experience_year
    end

    protected
    def get_numero_artigos
        return self.producoes_bibliograficas.count
    end

    protected
    def get_grau_formacao
        formacao = self.formacao_academica.sort_by { |formacao| formacao['data_fim'] }.reverse.first
        if formacao.titulo.downcase.include? "doutor"
            return 4
        elsif formacao.titulo.include? "mestr"
            return 3
        elsif formacao.titulo.include? "especiali"
            return 2
        elsif formacao.titulo.include? "gradua" and formacao.data_fim != "Atual"
            return 1
        else
            return 0
        end
    end

    def self.search_by(query)
        __elasticsearch__.search({
            sort: [ 
                {'ranking_pessoal': {"order": "desc"}},
                '_score', 
            ],
            query: {
                multi_match: {
                    query: query,
                    fields: ['nomeˆ10',
                        'descricaoˆ10',
                        'producoes_bibliograficas',
                        'formacao_academicas',
                        'formacao_complementar',
                        'areas_atuacao',
                        'projeto_pesquisa',
                        'orientados',
                        'premios',
                        'idiomas'],
                }
            }
        })
    end
end