require 'httparty'
require 'json'

class ProfileImport

  def initialize
    @escavador_parser_url = 'http://localhost:5000'
  end

  def search_by name
    list_of_results = []
    #chama do escavador
    response = HTTParty.get("#{@escavador_parser_url}/search?key=#{name}")
    response_json = JSON(response)
    list_of_results = response_json['results']
    return list_of_results
  end

  def parse_profile_of url
    params = url.split("/sobre/")[1].split('/')
    profile_json = JSON.parse(HTTParty.get("#{@escavador_parser_url}/sobre?sobre=/#{params[0]}/#{params[1]}"))
    import_profile_into_db profile_json
  end

  def import_profile_into_db profile_json
    Profile.create!(
        :nome => profile_json['nome'],
        :descricao => profile_json['descricao'],
        :producoes_bibliograficas => profile_json['producoes_bibliograficas'],
        :orientacao => profile_json['orientados'],
        :projeto_pesquisa => profile_json['projetos_pesquisa'],
        :area_atuacao => profile_json['areas_atuacao'],
        :idioma => profile_json['idiomas'],
        :premio => profile_json['premios'],
        :formacao_academica => profile_json['formacao_academica'],
        :formacao_complementar => profile_json['formacao_complementar'],
        :organizacao_eventos => profile_json['organizacao_eventos'],
        :outras_producoes => profile_json['outras_producoes']
      )
  end

end
