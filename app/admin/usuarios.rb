ActiveAdmin.register Usuario do
  decorate_with UsuarioDecorator

  permit_params :nombre, :email, :password, :password_confirmation, :foto, :rol_id

  menu label: 'Usuarios', parent: 'Administración', priority: 10

  index do
    column :nombre_
    column :email
    column :current_sign_in_at
    column :created_at
  end

  show title: :nombre do
    attributes_table do
      if usuario.foto?
        row :foto do
          image_tag usuario.foto.chica.url
        end
      end
      row :email
      row :rol
      row :sign_in_count
      row :reset_password_sent_at
      row :remember_created_at
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      row :current_sign_in_ip
      row :last_sign_in_ip
      row :confirmed_at
      row :confirmation_send_at
      row :locked_at
    end
    active_admin_comments
  end

  filter :nombre
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs do
      f.input :nombre
      f.input :email
      f.input :rol
      f.input :foto
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  action_item :ocultar_ver_side_bar, only: :index do
    link_to "Ocultar/Ver filtro","#", {id: 'ocultar_ver_side_bar'}
  end

  member_action :filtro, method: :get, format: :json do
    @usuario = Usuarior.find(params['id'])
    salida = {}
    case params['accion']
    when 'consultar'
    when 'ver'
      @usuario.update_attribute(:ver_filtro, true)
    when 'ocultar'
      @usuario.update_attribute(:ver_filtro, false)
    end
    salida = {respuesta: (@usuario.ver_filtro ? 'S' : 'N')}
    respond_to do |format|
      format.json {render json: salida}
    end
  end
end
