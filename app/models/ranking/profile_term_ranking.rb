require 'Date'

class ProfileTermRanking

  SECTION_WEIGHTS = {
    'DP' => 3, # DESCRICAO DO PERFIL
    'FR' => 3, # FORMACAO
    'AA' => 3, # AREA DE ATUACAO
    'OE' => 4, # ORGANIZACAO DE EVENTOS
    'SP' => 13 # SECAO DE PUBLICACOES
  }

  # PESOS: SECAO DE PUBLICACOES
  SP_SECTION_WEIGHTS = {
    'PB' => 4, # PRODUCOES BIBLIOGRAFICAS
    'OR' => 2, # ORIENTOU
    'OP' => 1, # OUTRAS PRODUCOES
    'PP' => 3  # PROJETOS DE PESQUISA
  }

  def initialize(profile, terms)
    @profile = profile
    @terms = terms
  end

  def calculate_term_distance_for_description_section
    # para a determinada sessao calcula a distancia dos termos
    return self.calculate_term_distance @profile.descricao
  end

  def calculate_term_distance_for_graduation_section
    total_graduation_distance = 0.0
    @profile.each do |formacao|
      total_formacao_distance = 0.0
      formacao.outros_dados.each do |dado|
        total_formacao_distance += self.calculate_term_distance dado
      end
      total_graduation_distance += total_formacao_distance
    end
    return total_graduation_distance
  end

  def calculate_term_distance_for_area_section
    total_area_distance = 0.0
    @profile.area_atuacao.each do |area|
      especialidade_distance = self.calculate_term_distance area.especialidade
      sub_area_distance = self.calculate_term_distance area.sub_area
      grande_area_distance = self.calculate_term_distance area.grande_area
      area_distance = self.calculate_term_distance area.area
      total_area_distance += specialidade + sub_area + grande_area + area
    end
    return total_area_distance
  end

  ##
  # TODO este campo nao existe no profile ainda.
  ##
  def calculate_term_distance_for_events_section
    total_events_distance = 0.0
    return total_events_distance
  end

  ##
  # Publications_section has a separated method
  ##
  def calculate_term_distance_for_publications_section
    mp_pb = self.calctulate_pub_term_for_publications_section
    mp_or = self.calctulate_pub_term_for_oriented_section
    mp_op = self.calculate_pub_term_for_other_productions_section
    mp_pp = self.calculate_pub_term_for_research_projects_section

    return (mp_pb * SECTION_WEIGHTS['PB'] + mp_or * SECTION_WEIGHTS['OR'] +
      mp_op * SECTION_WEIGHTS['OP'] + mp_pp * SECTION_WEIGHTS['PP'])/10
  end

  def calctulate_pub_term_for_publications_section
    mp_publications_section_total = 0.0
    @profile.producoes_bibliograficas.each do |producao|
      pub_year_weight = 0
      pub_year = producao[/, \b[0-9]{4}\b\./]
      if pub_year
          pub_year = pub_year[/[0-9]{4}/].to_i
          pub_year_weight = self.get_weight_by_date pub_year
      end
      term_distance = calculate_term_distance producao
      mp_publications_section_total += term_distance + pub_year_weight
    end
    return mp_publications_section_total / @profile.producoes_bibliograficas.length
  end

  def calctulate_pub_term_for_oriented_section
    mp_oriented_section_total = 0.0
    @profile.orientacao.each do |orientacao|
      pub_year_weight = 0
      pub_year = orientacao.descricao[/; [0-9]{4}\b;/]
      if pub_year
        pub_year = pub_year[/[0-9]{4}/].to_i
        pub_year_weight = self.get_weight_by_date pub_year
      end
      term_distance = calculate_term_distance orientacao.descricao
      mp_oriented_section_total += term_distance + pub_year_weight
    end
    return mp_oriented_section_total / @profile.orientacao.length
  end

  ##
  # TODO este campo nao existe no profile ainda.
  ##
  def calculate_pub_term_for_other_productions_section
    mp_other_productions_total = 0.0
    return mp_other_productions_total
  end

  def calculate_pub_term_for_research_projects_section
    mp_research_projects_total = 0.0
    @profile.projeto_pesquisa.each do |projeto|
      pub_year = projeto.inicio
      if projeto.fim != "Atual"
        pub_year = projeto.fim
      end
      pub_year_weight = self.get_weight_by_date pub_year
      term_distance = calculate_term_distance projeto.pesquisa
      mp_research_projects_total += term_distance + pub_year_weight
    end
    return mp_oriented_section_total / @profile.projeto_pesquisa.length
  end

  ##
  # TODO
  ##
  protected
  def get_weight_by_date(date_year)
    this_year = Date.today.year
    distance_from_today = this_year - date_year
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
      np = self.calculate_unigrams_of section_text
    elsif @terms.length == 2
      np = self.calculate_ngrams_of section_text
    elsif @terms.length == 3
      np = self.calculate_trigrams_of section_text
    end
    return np != -1 ? (1/(1.0 + np)) : 0
  end

  ##
  # Unique word to be found, NP always 1
  ##
  private
  def calculate_unigrams_of section_text
    section_text_words = section_text.split(' ')
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
    first_word_index = section_text_words.index {|word| word.gsub(/[,.!?;:*(){}'"\[\]#@&%]/, '').upcase == @terms.first.upcase}
    last_word_index = section_text_words.index {|word| word.gsub(/[,.!?;:*(){}'"\[\]#@&%]/, '').upcase == @terms.last.upcase}
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

  def calculate_term_ranking
    dt_dp = self.calculate_term_distance_for_description_section
    dt_fr = self.calculate_term_distance_for_graduation_section
    dt_aa = self.calculate_term_distance_for_area_section
    dt_oe = self.calculate_term_distance_for_events_section
    dt_sp = self.calculate_term_distance_for_publications_section

    return (dt_dp * SECTION_WEIGHTS['DP'] + dt_fr * SECTION_WEIGHTS['FR'] +
      dt_aa * SECTION_WEIGHTS['AA'] + dt_oe * SECTION_WEIGHTS['OE']
      dt_sp * SECTION_WEIGHTS['SP'])/26
  end

end
