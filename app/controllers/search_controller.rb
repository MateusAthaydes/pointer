class SearchController < ApplicationController
    def search
        if params[:q].nil?
            @profiles = []
        else
            @profiles = Profile.search_by params[:q]
        end
    end

    def home
        render layout: false
    end
end
