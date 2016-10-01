class SearchController < ApplicationController
    def search
        if params[:q].nil?
            @articles = []
        else
            @articles = Profile.search params[:q]
        end
    end
end
