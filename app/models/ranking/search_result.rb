require_relative 'profile_term_ranking'

class SearchResult

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
      # sort by: term, relations and then personal 
    end
  end

  def say_hello
    puts "\n\n HELLO! \n\n"
  end

end
