class ProfilesController < ApplicationController
    def index
        @profiles = Profile.all
    end

    def show
        @profiles = Profile.find params[:id]
    end
end
