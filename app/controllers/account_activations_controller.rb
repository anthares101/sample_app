class AccountActivationsController < ApplicationController
    def edit
        unless User.where(email: params[:email]).count == 0
            user = User.find_by(email: params[:email])
        end
        if user && !user.activated? && user.authenticated?(:activation, params[:id])
            user.activate
            log_in user
            flash[:success] = "Account activated!"
            redirect_to user
        else
            flash[:danger] = "Invalid activation link"
            redirect_to root_url
        end
    end
end
