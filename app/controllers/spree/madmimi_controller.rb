# coding: utf-8
require 'madmimi'

module Spree
	class MadmimiController < Spree::StoreController
		protect_from_forgery with: :null_session 
		
		# before_filter :load_api
		before_filter :retrieve_utm_cookies, only: [:subscribe]
		layout "spree/layouts/spree_application"

		before_action :load_subscriber, :only => :unsub
		rescue_from ActiveRecord::RecordNotFound, :with => :redirect_to_home

		# def load_api
		#	 @mimi = MadMimi.new(ENV['MAD_EMAIL'], ENV['MAD_APIKEY'])
		# end

		def subscribe
			@errors = []
			email = params[:subscriber][:email]
			params[:alert_lightbox] ||= true

			if email.blank?

				@errors << t("spree.madmimi.subscribe.blank_email")

			elsif email !~ /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i

				@errors << t("spree.madmimi.subscribe.email_invalid")

			else

				if params[:alert_lightbox] == "false"
					@alert_success = false
					session[:return_user_to] = root_url + "?from=landing_cadastro"
				else
					@alert_success = true
				end

				@subscriber = Spree::Subscriber.where(email:email).first
				unless @subscriber
					@subscriber = Spree::Subscriber.create(subscriber_parameters)
				end
				if @subscriber.is_subscribed?
					@errors << t("spree.madmimi.subscribe.already_subscribed")
				else
					@subscriber.subscribe
				end
			end

			respond_to do |format|
				format.js { render :layout => false }
			end
		end

		def success
			flash[:newsletter_subscription_tracking] = "nothing special"
			respond_to do |format|
				format.html
			end
		end

		def unsub
			if @user.flag_email?
				begin
					@user.update_attribute(:flag_email, false)
					flash[:notice] = "Inscrição retirada com sucesso"
				rescue => e
					flash[:notice] = "Não foi possível remover a inscrição"
					puts e.message
				end
			else
				flash[:notice] = "Inscrição retirada com sucesso"
			end
		end

		private

		def redirect_to_home
    		flash[:error] = "Usuário não encontrado"
    		redirect_to "/", :status => :moved_permanently
  		end

		def load_subscriber
			@user = Spree::User.find_by_referral_token(params[:id])
		end

		def subscriber_parameters
			params[:subscriber][:subscribed] = true
			params[:subscriber][:update] = Date.today
			params[:subscriber].permit(:email, :nome, :utm_source, :utm_medium, :utm_campaign, :utm_term, :profile, :ubdate, :subscribed)
		end

		def retrieve_utm_cookies
			cookies.permanent[:utm_source] = cookies[:original_utm_source] if cookies[:original_utm_source]
			cookies.permanent[:utm_campaign] = cookies[:original_utm_campaign] if cookies[:original_utm_campaign]
			cookies.permanent[:utm_medium] = cookies[:original_utm_medium] if cookies[:original_utm_medium]
			cookies.permanent[:utm_term] = cookies[:original_utm_term] if cookies[:original_utm_term]

			params[:subscriber][:utm_source] = cookies[:original_utm_source] if cookies[:original_utm_source]
			params[:subscriber][:utm_campaign] = cookies[:original_utm_campaign] if cookies[:original_utm_campaign]
			params[:subscriber][:utm_medium] = cookies[:original_utm_medium] if cookies[:original_utm_medium]
			params[:subscriber][:utm_term] = cookies[:original_utm_term] if cookies[:original_utm_term]
		end

	end
end
