require 'elasticsearch/model'
require 'elasticsearch/dsl'
require 'mongoid'
require 'Date'
require 'set'
Mongoid.connect_to 'profiles'

class Profile
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
    store_in collection: 'profiles'

    # index name for keeping consistency among existing environments
    index_name "profiles-#{Rails.env}"

    field :nome, type: String, default: ''
    field :descricao, type: String, default: ''
    field :producoes_bibliograficas, type: Array, default: []
    field :ranking_pessoal, type: Float, default: 0.0
    field :nome_citacoes, type: Array, default []

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
        document.nome_citacoes = document.create_nome_citacoes

        personal_ranking_value = document.calculate_personal_ranking
        document.ranking_pessoal = personal_ranking_value
    end

    def create_nome_citacoes
      # MÓRA, M. C.;MORA, M.C.;Móra, Michael da Costa;Mora, Michael da Costa
      nome_citacoes = Array.new

      # MICHAEL DA COSTA MORA
      nome_citacoes.append(self.nome.upcase!)

      nome_list = self.nome.split " "
      last_name = nome_list.pop + ","

      # MORA, MICHAEL DA COSTA
      citacao = last_name + nome_list.join(' ')
      nome_citacoes.append(citacao)

      # MORA, M. C.
      citacao = last_name
      nome_list.each do |nome|
        citacao += nome + "."
      end
      nome_citacoes.append(citacao)
      return nome_citacoes
    end

    #
    ## O ranking pessoal é dado por:
    ## Média ponderada de:
    ## (AR) Tempo em atividade recente - peso 3
    ## (XP) Tempo de experiência - peso 1
    ## (NA) Número de artigos - peso 4
    ## (GR) Grau de formação - peso 2
    #
    def calculate_personal_ranking
        atividade_recente = self.get_atividade_recente
        experiencia = self.get_tempo_experiencia
        numero_artigos = self.get_numero_artigos
        grau_formacao = self.get_grau_formacao

        return (atividade_recente * 3 + experiencia * 1 + numero_artigos * 4 + grau_formacao * 2) / 10
    end

    #
    ## O ranking de relacoes se trata do somatorio do ranking pessoal de cada um
    ## dos perfis os quais o perfil atual se relaciona.
    #
    def calculate_relationship_ranking
      # Descobrir as relacoes:
        # Orientados
        # Projetos de Pesquisa
        # Producoes Bibliograficas
        # Formacao academica?
      # Consultar o RP de cada uma
      # Somar os RPs e retornar
      orientados = self.get_relations_of_orientados
      projetos = self.get_relations_of_projetos_pesquisa
      producoes = self.get_relations_of_producoes_bibliograficas

      relations = orientados | projetos | producoes
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
            if formacao.data_fim != 'Atual'
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
        if formacao.titulo.downcase.include? 'doutor'
            return 4
        elsif formacao.titulo.include? 'mestr'
            return 3
        elsif formacao.titulo.include? 'especiali'
            return 2
        elsif formacao.titulo.include? 'gradua' and formacao.data_fim != 'Atual'
            return 1
        else
            return 0
        end
    end

    protected
    def get_relations_of_orientados
      orientados = Set.new
      self.orientacao.each do |orientacao|
        relation = Profile.find_by(:nome => orientacao.nome)
        if relation
          orientados.add(relation)
        else
          # Chama o servico python pra inserir a partir de orientacao.link
          # Adiciona na lista de orientados
        end
      end
      return orientados_relations
    end

    protected
    def get_relations_of_projetos_pesquisa
      relations = Set.new
      self.projeto_pesquisa.each do |projeto|
        integrantes = projeto.pesquisa[/Integrantes: .*\./].slice!('Integrantes: ')
        integrantes.each do |integrante|
          integrante_name = integrante.slice(/ - .*$/)
          relation = Profile.find_by(:nome => integrante_name)
          if relation
            relations.add(relation)
          else
            # Chama o servico python pra inserir a partir de orientacao.link
            # Adiciona na lista de orientados
          end
        end
      end
      return relations
    end

    protected
    def get_relations_of_producoes_bibliograficas
      relations = Set.new
      sef.producoes_bibliograficas.each do |producao|
        collaborators = proucao.split(/\ \. /).first.split(/ ; /)
        collaborators.each do |collaborator|
          collaborator.gsub!(/\s+/, "")
          # ver se assinatura está em algum profile
          Profile.find_by(:nome_citacoes => )
          relations.add()
        end
      end
      return relations
    end

    def self.search_by(query)
      result = __elasticsearch__.search({
            sort: [
                {'ranking_pessoal': {"order": "desc"}}
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
                        'idiomas'
                    ],
                }
            }
        })
        return result
    end
end
