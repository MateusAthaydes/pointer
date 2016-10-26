require_relative 'profile_term_ranking'

class SearchResult

  SECTION_WEIGHTS = {
    'DP' => 3,
    'FR' => 3,
    'AA' => 3,
    'OE' => 4,
    'SP' => 13
  }

  SP_SECTION_WEIGHTS = {
    'PB' => 4,
    'OR' => 2,
    'OP' => 1,
    'PP' => 3
  }

  def initialize(query, elasticsearch_result)
    @terms = query.split(' ')
    @elasticsearch_result = elasticsearch_result
  end

  def get_search_ordered_result
    @elasticsearch_result.each do |result|
      profile_ranking = ProfileTermRanking.new(result, @terms)
      profile_ranking
    end
  end

  def say_hello
    puts "\n\n HELLO! \n\n"
  end

end
