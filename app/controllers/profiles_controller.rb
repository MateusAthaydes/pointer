require 'json'
require './app/models/import_engine/profile_import'
class ProfilesController < ApplicationController
    def index
        @profiles = Profile.order(:nome => 'asc')
    end

    def show
        @profile = Profile.find params[:id]
    end

    def import
      # get results from escavador
      profile_import = ProfileImport.new
      @list_of_results = profile_import.search_by params[:import_name]
      @list_of_results.sort_by! { |result| result['descricao'].length }.reverse!
    end

    def parse_and_import
      request.raw_post
      body_response = JSON.parse(request.body.read)
      profile_import = ProfileImport.new
      profile_import.parse_profile_of body_response['selected_profile']
    end

end
