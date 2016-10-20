require 'elasticsearch/model'
require 'elasticsearch/dsl'
require 'mongoid'
require 'Date'
require 'set'
require 'i18n'
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
        document.nome_citacoes = document.create_researcher_quotation
        document.ranking_pessoal = document.calculate_personal_ranking
    end

    set_callback(:save, :after) do |document|
      # The relation ranking should be calculated after the save, to garantee
      # that all profiles already have their personal ranking calculated
      document.ranking_relacoes = calculate_relationship_ranking
    end

    ##
    # Create a list of possible quotes for the researcher
    # This is necessary as long as we use escavador as data source
    ##
    def create_researcher_quotation
      nome_citacoes = Array.new
      initials = []
      self.clean_name_string! self.nome
      nome_list = cleaned_name.split ' '
      nome_list.each{|n| initials << n[0]}

      initials_first_index = 0
      initials_last_index = initials.length - 1
      nome_list_last_index = nome_list.length - 1

      # 1. MICHAEL DA COSTA MORA
      citacao = self.nome.upcase
      nome_citacoes << citacao

      # 2. MICHAEL C. M.
      citacao = nome_list.first + ' ' + initials.list_without_element(initials_first_index).join('. ') + '.'
      nome_citacoes << citacao

      # 3. MICHAEL C. MORA
      citacao = nome_list.first + ' ' + initials.list_without_list_of_elements([initials_first_index, initials_last_index]).join('. ') + '. ' + nome_list.last
      nome_citacoes << citacao

      # 4. M. C, MORA
      citacao = initials.list_without_element(initials_last_index).join('. ') + ', ' + nome_list.last
      nome_citacoes << citacao

      # 5. MORA, MICHAEL DA COSTA
      rest_of_name = nome_list.list_without_element(nome_list_last_index)
      last_name_formatted = nome_list.list_without_list_of_elements((0..(rest_of_name.length - 1))).join('') + ', '

      citacao = last_name_formatted + ', ' + rest_of_name.join(' ')
      nome_citacoes << citacao

      # 6. MORA, M. C.
      citacao = last_name_formatted + initials.list_without_element(initials_last_index).join('. ') + '.'
      nome_citacoes << citacao

      return nome_citacoes
    end

    ##
    # Trasnform the name into upcase
    # Remove accents
    # Remove 'da, do, de' and that kind of stuff from the name of the researcher
    ##
    def clean_name_string(name)
      cleaned_name = name.upcase
      cleaned_name = I18n.transliterate(cleaned_name)
      # remove 'da, do, de' do nome (nao servem para nada em termos de citacoes)
      cleaned_name = cleaned_name[/\b[\w]{1,2}\b/]
      # to make a trim: .gsub!(/\s+/, "")
      return cleaned_name
    end

    #
    ## Basically, the personal ranking is:
    ## weighted average of:
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
      relashionship_ranking = 0.0

      relations.each do |relation|
        relationship_ranking += relation.ranking_pessoal
      end

      return relashionship_ranking
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
          end
        end
      end
      return relations
    end

    protected
    def get_relations_of_producoes_bibliograficas
      relations = Set.new
      self.producoes_bibliograficas.each do |producao|
        collaborators = proucao.split(/\ \. /).first.split(/ ; /)
        collaborators.each do |collaborator|
          collaborator_quotation = self.clean_name(collaborator)
          # ver se assinatura está em algum profile
          relation = Profile.find_by(:nome_citacoes => collaborator_quotation)
          relations.add(relation)
        end
      end
      return relations
    end

    ##
    # Elasticsearch search query method
    ##
    def self.search_by(query)
      result = __elasticsearch__.search({
            sort: [
                {'ranking_pessoal': {"order": "desc"}}
            ],
            query: {
                multi_match: {
                    query: query,
                    fields: ['nome^10',
                        'descricao^10',
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

class Array
  ##
  # Get the actual list and removes the element given by parameter(The parameter must be the element index).
  # This method doesnt modify the original list, it returns a copy of that without the element
  ##
  def list_without_element(element_index)
      self_cloned = self.clone
      self_cloned.delete_at element_index
      return self_cloned
  end

  ##
  # Do the same as the list_without_element, but accepting a list of elements
  ##
  def list_without_list_of_elements(list_of_index_elements)
    self_cloned = self.clone
    list_of_index_elements.sort.reverse.each do |element_index|
      self_cloned.delete_at element_index
    end
    return self_cloned
  end
end
