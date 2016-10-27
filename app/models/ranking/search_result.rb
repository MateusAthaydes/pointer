require_relative 'profile_term_ranking'

class SearchResult

  GENERAL_RANKING_WEIGHTS = {
    'RP' => 3,
    'RR' => 2,
    'RT' => 5
  }

  def initialize(query, elasticsearch_result)
    @terms = query.split(' ')
    @elasticsearch_result = elasticsearch_result
  end

  def get_search_ordered_result
    @elasticsearch_result.each do |result|
      profile_term = ProfileTermRanking.new(result, @terms)
      personal_ranking = result.ranking_pessoal
      relations_ranking = result.ranking_relacoes
      term_ranking = profile_term.calculate_term_ranking
      general_ranking = (personal_ranking * GENERAL_RANKING_WEIGHTS['RP'] + relations_ranking * GENERAL_RANKING_WEIGHTS['RR']
        + term_ranking * GENERAL_RANKING_WEIGHTS['RT']) / 10

      # ver se isso insere um atributo genreal_ranking no profile, ou ao menos no result.
      result.general_ranking = general_ranking
    end
    # Sort by general_ranking
    @elasticsearch_result.sort! { |result1, result2| result1.general_ranking <=> result2 }
  end

  def say_hello
    puts "\n\n HELLO! \n\n"
  end

end
