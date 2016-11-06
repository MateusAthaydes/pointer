require 'Date'

class ProfileTermRanking

  # PESOS: SECOES DO PERFIL
  SECTION_WEIGHTS ||= {
    'DP' => 3, # DESCRICAO DO PERFIL
    'FR' => 3, # FORMACAO
    'AA' => 3, # AREA DE ATUACAO
    'OE' => 4, # ORGANIZACAO DE EVENTOS
    'SP' => 13 # SECAO DE PUBLICACOES
  }

  # PESOS: SECAO DE PUBLICACOES
  SP_SECTION_WEIGHTS ||= {
    'PB' => 4, # PRODUCOES BIBLIOGRAFICAS
    'OR' => 2, # ORIENTOU
    'OP' => 1, # OUTRAS PRODUCOES
    'PP' => 3  # PROJETOS DE PESQUISA
  }

  def initialize(profile, terms)
    @profile = profile
    @terms = terms
  end

  def calculate_term_ranking
    dt_dp = calculate_term_distance_for_description_section
    dt_fr = calculate_term_distance_for_graduation_section
    dt_aa = calculate_term_distance_for_area_section
    dt_oe = calculate_term_distance_for_events_section
    dt_sp = calculate_term_distance_for_publications_section

    return (dt_dp * SECTION_WEIGHTS['DP'] + dt_fr * SECTION_WEIGHTS['FR'] + dt_aa * SECTION_WEIGHTS['AA'] + dt_oe * SECTION_WEIGHTS['OE'] + dt_sp * SECTION_WEIGHTS['SP'])/26
  end

  def calculate_term_distance_for_description_section
    # para a determinada sessao calcula a distancia dos termos
    return calculate_term_distance(@profile.descricao || '')
  end

  def calculate_term_distance_for_graduation_section
    total_graduation_distance = 0.0
    @profile.formacao_academicas.each do |formacao|
      total_formacao_distance = 0.0
      formacao.outros_dados.each do |dado|
        total_formacao_distance += calculate_term_distance(dado || '')
      end
      total_graduation_distance += total_formacao_distance
    end
    return total_graduation_distance
  end

  def calculate_term_distance_for_area_section
    total_area_distance = 0.0
    if @profile.try(:areas_atuacao)
      @profile.areas_atuacao.each do |area|
        especialidade_distance = calculate_term_distance(area.especialidade || '')
        sub_area_distance = calculate_term_distance(area.sub_area || '')
        grande_area_distance = calculate_term_distance(area.grande_area || '')
        area_distance = calculate_term_distance(area.area || '')
        total_area_distance += especialidade_distance + sub_area_distance + grande_area_distance + area_distance
      end
    end
    return total_area_distance
  end

  ##
  # TODO este campo nao existe no profile ainda.
  ##
  def calculate_term_distance_for_events_section
    total_events_distance = 0.0
    if @profile.try(:organizacao_eventos)
      @profile.organizacao_eventos.each do |evento|
        total_events_distance += calculate_term_distance evento
      end
    end
    return total_events_distance
  end

  ##
  # Publications_section has a separated method
  ##
  def calculate_term_distance_for_publications_section
    mp_pb = calctulate_pub_term_for_publications_section
    mp_or = calctulate_pub_term_for_oriented_section
    mp_op = calculate_pub_term_for_other_productions_section
    mp_pp = calculate_pub_term_for_research_projects_section

    return (mp_pb * SP_SECTION_WEIGHTS['PB'] + mp_or * SP_SECTION_WEIGHTS['OR'] + mp_op * SP_SECTION_WEIGHTS['OP'] + mp_pp * SP_SECTION_WEIGHTS['PP'])/10
  end

  def calctulate_pub_term_for_publications_section
    mp_publications_section_total = 0.0
    if @profile.try(:producoes_bibliograficas)
      @profile.producoes_bibliograficas.each do |producao|
        pub_year_weight = 0
        pub_year = producao[/, \b[0-9]{4}\b\./]
        if pub_year
            pub_year = pub_year[/[0-9]{4}/].to_i
            pub_year_weight = get_weight_by_date pub_year
        end
        term_distance = calculate_term_distance(producao || '')
        mp_publications_section_total += term_distance + pub_year_weight
      end
      number_of_publications = @profile.producoes_bibliograficas.length == 0 ? 1 : @profile.producoes_bibliograficas.length
      return mp_publications_section_total / number_of_publications
    end
    return mp_publications_section_total
  end

  def calctulate_pub_term_for_oriented_section
    mp_oriented_section_total = 0.0
    if @profile.try(:orientados)
      @profile.orientados.each do |orientacao|
        pub_year_weight = 0
        pub_year = orientacao.descricao[/; [0-9]{4}\b;/]
        if pub_year
          pub_year = pub_year[/[0-9]{4}/].to_i
          pub_year_weight = get_weight_by_date pub_year
        end
        term_distance = calculate_term_distance(orientacao.descricao || '')
        mp_oriented_section_total += term_distance + pub_year_weight
      end
      number_of_orientados = @profile.orientados.length == 0 ? 1 : @profile.orientados.length
      return mp_oriented_section_total / number_of_orientados
    end
    return mp_oriented_section_total
  end

  def calculate_pub_term_for_other_productions_section
    mp_other_productions_total = 0.0
    if @profile.try(:outras_producoes)
      @profile.outras_producoes.each do |producao|
        pub_year_weight = 0
        pub_year = producao[/\. [0-9]{4}./]
        if pub_year
          pub_year = pub_year[/[0-4]{4}/].to_i
          pub_year_weight = get_weight_by_date pub_year
        end
        term_distance = calculate_term_distance producao
        mp_other_productions_total += term_distance + pub_year_weight
      end
      number_of_other_productions = @profile.outras_producoes.length == 0 ? 1 : @profile.outras_producoes.length
      return mp_other_productions_total / number_of_other_productions
    end
    return mp_other_productions_total
  end

  def calculate_pub_term_for_research_projects_section
    mp_research_projects_total = 0.0
    if @profile.try(:projetos_pesquisa)
      @profile.projeto_pesquisa.each do |projeto|
        pub_year = projeto.inicio
        if projeto.fim != "Atual"
          pub_year = projeto.fim
        end
        pub_year_weight = get_weight_by_date pub_year
        term_distance = calculate_term_distance(projeto.pesquisa || '')
        mp_research_projects_total += term_distance + pub_year_weight
      end
      number_of_orientados = @profile.projeto_pesquisa.length == 0 ? 1 : @profile.projeto_pesquisa.length
      return mp_research_projects_total / number_of_orientados
    end
    return mp_research_projects_total
  end

  protected
  def get_weight_by_date(date_year)
    this_year = Date.today.year
    distance_from_today = this_year - date_year.to_i
    case
    when distance_from_today <= 3
      return 10
    when distance_from_today > 3 && distance_from_today <= 6
      return 7
    when distance_from_today > 6 && distance_from_today <= 10
      return 5
    when distance_from_today > 10
      return 2
    end
  end

  protected
  def calculate_term_distance(section_text)
    if @terms.length == 1
      np = calculate_unigrams_of section_text
    elsif @terms.length == 2
      np = calculate_bigrams_of section_text
    elsif @terms.length == 3
      np = calculate_trigrams_of section_text
    else
      np = 0
    end
    return np != -1 ? (1/(1.0 + np)) : 0
  end

  ##
  # Unique word to be found, NP always 1
  ##
  private
  def calculate_unigrams_of section_text
    section_text_words = section_text.to_s.split(' ')
    word_index = section_text_words.index {|word| word.gsub(/[,.!?;:*(){}'"\[\]#@&%]/, '').upcase == @terms.first.upcase}
    if word_index
      return 0
    else
      return -1
    end
  end

  ##
  # Inteligencia palavra1 palavra2 Artificial, NP = 2
  ##
  private
  def calculate_bigrams_of section_text
    section_text_words = section_text.split(' ')
    # This regex removes all symbols of the string
    first_word_index = section_text_words.index {|word| word.gsub(/[,.!?;:*(){}'"\[\]#@&%]/, '').upcase == @terms.first.upcase} || -1
    last_word_index = section_text_words.index {|word| word.gsub(/[,.!?;:*(){}'"\[\]#@&%]/, '').upcase == @terms.last.upcase} || -1
    np = (last_word_index - first_word_index) - 1
    if np >= 0
      return np
    else
      return -1
    end
  end

  ##
  # TODO
  # Ciencia palavra1 da palavra2 palavra3 Computacao, NP = 3
  ##
  private
  def calculate_trigrams_of section_text
    return 0
  end

end
