ActiveAdmin.register Comuna do
  decorate_with ComunaDecorator

  permit_params :nombre, :provincia

  menu label: 'Comunas', parent: 'Tablas', priority: 9980

  index do
    column :nombre_
    column :provincia
    column :region
  end

  filter :nombre
  filter :provincia_id, as: :search_select_filter, display_name: 'nombre', fields: [:nombre], order_by: 'nombre_asc'
  filter :region_id,    as: :search_select_filter, display_name: 'titulo', fields: [:titulo], order_by: 'titulo_asc'

  action_item :ocultar_ver_side_bar, only: :index do
    link_to "Ocultar/Ver filtro","#", {id: 'ocultar_ver_side_bar'}
  end
end
