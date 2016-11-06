# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

File.readlines('db/seeds/profiles.json').each do |profile_json|
    json_line = ActiveSupport::JSON.decode(profile_json)
    Profile.create!(
        :nome => json_line['nome'],
        :descricao => json_line['descricao'],
        :producoes_bibliograficas => json_line['producoes_bibliograficas'],
        :orientacao => json_line['orientados'],
        :projeto_pesquisa => json_line['projetos_pesquisa'],
        :area_atuacao => json_line['areas_atuacao'],
        :idioma => json_line['idiomas'],
        :premio => json_line['premios'],
        :formacao_academica => json_line['formacao_academica'],
        :formacao_complementar => json_line['formacao_complementar'],
        :organizacao_eventos => json_line['organizacao_eventos'],
        :outras_producoes => json_line['outras_producoes'])
end
puts "Done Reading. Everything was inserted into mongoid database and elasticsearch."
