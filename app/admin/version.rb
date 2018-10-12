ActiveAdmin.register PaperTrail::Version, as: 'Seguimiento' do

  config.batch_actions = false
  menu :parent => "Administración", :priority => 1000

  actions :index

  index do
    column :id
    column 'Tipo',:item_type
    column 'Evento',  :event
    column :item_id
    column('Datos', :object) do |r|
      salida = (if r.object.nil?
                  '---'
                else #if r.item.nil?
                  r.object.gsub(/\n/, '<br>')
                end)
      #salida << "<br>" + r.ot_datos unless r.ot_datos.blank?
      salida.html_safe
    end
    column('Quien', :whodunnit) do |r|
      x = r.whodunnit
      if x.nil?
        '---'
      elsif x =~ /\A\d{1,9}\z/
        if (au = Usuario.find(x)).nil?
          x
        else
          link_to( "(#{x}) #{au.nombre}", [:admin, au])
        end
      else
        x
      end
    end
    column( "Creado el", :created_at){|r| r.created_at.to_s(:db)}
  end

  filter :item_type, label: 'Tipo', as: :select, collect: ->{PaperTrail::Version.distinct.pluck(:item_type)}
  filter :item_id
  filter :event, label: 'Evento', as: :select, collect: ->{PaperTrail::Version.distinct.pluck(:event)}
  filter :whodunnit, label: 'Quien'
  filter :object, label: 'Datos'
  filter :created_at, label: 'Cuando'

  action_item :ocultar_ver_side_bar, only: :index do
    link_to "Ocultar/Ver filtro","#", {id: 'ocultar_ver_side_bar'}
  end
end
