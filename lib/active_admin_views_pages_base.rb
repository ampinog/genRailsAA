# lib/active_admin_views_pages_base.rb

class ActiveAdmin::Views::Pages::Base < Arbre::HTML::Document

  private

  def build_flash_messages
    div class: 'flashes' do
      flash_messages.each do |type, message|
        div class: "flash flash_#{type}" do
          message.html_safe
        end
      end
    end
  end

  # Renders the content for the footer
  def build_footer
    div class: "mi_footer_before" do
      "&nbsp;".html_safe
    end
    div :id => "ap_footer" do
      #div :class => "ap_izda" do
      div :class => "ap_centro" do
        "Copyright &copy; #{Date.today.year.to_s} [Op.Rental], construido por: #{link_to('angel pino', 'http://www.logisticadigital.org')}.".html_safe
      end
      #div :class => "ap_centro" do
      #  "**<strong>DEMOSTRATIVO</strong>**".html_safe
      #end
    end
  end

end
