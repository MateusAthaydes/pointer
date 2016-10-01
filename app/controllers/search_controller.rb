class SearchController < ApplicationController
    def search
        if params[:q].nil?
            @profiles = []
        else
            @profiles = Profile.search params[:q]
        end
    end
end
