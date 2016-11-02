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
    @elasticsearch_result.sort_by do |result|
      # Sort by general_ranking
      calculate_general_ranking! result
      result._source.ranking_geral
    end.reverse!
  end

  def calculate_general_ranking! result
    puts "\n *******#{result.nome}******** \n"
    profile_term = ProfileTermRanking.new(result, @terms)
    personal_ranking = result.ranking_pessoal
    relations_ranking = result.ranking_relacoes
    term_ranking = profile_term.calculate_term_ranking
    general_ranking = (personal_ranking * GENERAL_RANKING_WEIGHTS['RP'] + relations_ranking * GENERAL_RANKING_WEIGHTS['RR'] + term_ranking * GENERAL_RANKING_WEIGHTS['RT']) / 10

    puts "\n\npersonal_ranking: #{personal_ranking}"
    puts "relations_ranking: #{relations_ranking}"
    puts "term_ranking: #{term_ranking}"

    puts "\n\nGENERAL RANKING: #{general_ranking}"

    # Added general ranking and term ranking to the profile source, to show in view
    result._source.ranking_termo = term_ranking
    result._source.ranking_geral = general_ranking
  end

  def say_hello
    puts "\n\n HELLO! \n\n"
  end

end
