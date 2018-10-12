ActiveAdmin.register Provincia do
  decorate_with ProvinciaDecorator

  permit_params :nombre, :region_id

  menu label: 'Provincia', parent: 'Tablas', priority: 9990

  index do
    column :nombre_
    column :region
  end
  filter :nombre
  filter :region_id, as: :search_select_filter, display_name: 'titulo', fields: [:titulo], order_by: 'titulo_asc'

  action_item :ocultar_ver_side_bar, only: :index do
    link_to "Ocultar/Ver filtro","#", {id: 'ocultar_ver_side_bar'}
  end
end
