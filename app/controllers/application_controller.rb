class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_paper_trail_whodunnit

  # Re-escribe build_footer  y build_flash_message metods en ActiveAdmin::Views::Pages
  require 'active_admin_views_pages_base.rb'

  protected


  def user_for_paper_trail
    usuario_signed_in? ? current_usuario&.id : 'NN'
  end 
end
