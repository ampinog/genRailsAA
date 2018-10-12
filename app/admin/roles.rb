ActiveAdmin.register Rol do

  decorate_with RolDecorator

  permit_params :nombre, :nivel,
    roles_tableas_attributes: [:id, :tabla_id, :clae, :otro_sino, :otro, :_destroy]

  menu label: 'Roles', parent: 'Administración', priority: 20

  index do
    column :nombre_
    column :nivel
    column :created_at
    column :updated_at
  end

  filter :nombre
  filter :nivel

  show title: :nombre do
    attributes_table do
      row :nivel
      table_for rol.roles_tablas do
        column :tabla
        column :crear
        column :leer
        column :actualizar
        column :eliminar
        column :otro_sino
        column :otro
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :nombre
      f.input :nivel
    end
    has_many :roles_tablas, new_record: 'Agregar tabla', allow_destroy: true, eading: 'Tablas' do |rota|
      rota.input :tabla
      rota.input :crear
      rota.input :leer
      rota.input :actualizar
      rota.input :eliminar
      rota.input :otro_sino
      rota.input :otro
    end
    f.actions
  end

  action_item :ocultar_ver_side_bar, only: :index do
    link_to "Ocultar/Ver filtro","#", {id: 'ocultar_ver_side_bar'}
  end
end
