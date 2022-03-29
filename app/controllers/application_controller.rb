class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, except: :index, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index, unless: :devise_controller?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :authenticate_user!

  private

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || authenticated_root_path || unauthenticated_root_path)
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(_resource_or_scope)
    unauthenticated_root_path
  end
end
