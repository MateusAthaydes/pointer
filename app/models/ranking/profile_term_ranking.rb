class ProfileTermRanking

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
  # TODO
  # Publications_section has a separated method
  ##
  def calculate_term_distance_for_publications_section
    #
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

  ##
  # TODO
  ##
  def calculate_term_ranking(profile)
    return 0.0
  end

end
