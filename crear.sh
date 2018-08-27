#!/bin/bash --login
es_numero='^-?[0-9]+([.][0-9]+)?$'
es_nombre='^[a-zA_Z]+[a-zA_Z0-9_-]+$'
app=$1
cmq=$2
gem=$3
if ! [[ $app =~ $es_nombre ]] ; then
   echo "ERROR Primer argumento: No es un nombre de aplicación valido" >&2; exit 1
fi
if [ -z "$cmq" ]
then
    echo "ERROR Segundo argumento: Debe ser password de usuario root de mySql.">&2; exit 1
fi
if ! [[ $gem =~ '[SNsn]' ]] ; then  
    echo "ERROR Tercer párametro debe ser s/n para indicar si se elimina y crea gemset."
fi
# Eliminar y crear base de datos *_development y *_test
mysql -u root -p$cmq -e "DROP DATABASE IF EXISTS ${app}_development;"
mysql -u root -p$cmq -e "DROP DATABASE IF EXISTS ${app}_test;"
echo "BD recreadas development y test"

# Eliminar app
rm -rf $app
echo "Eliminado ./$app"

# Preparara rvm ruby 2.4.4 y gemset igual a app
if [[ $gem =~ '[Ss]' ]] ; then
    rvm use 2.4.4
    rvm --force gemset delete $app
    rvm gemset create $app
    rvm gemset use $app
    echo "creado gemset $app"

    # Isnstalar rails 5.1 sin documentacion
    gem install rails -v 5.1 -N
    echo "rails 5.1 sin documentación instalado"
else
    rvm use 2.4.4
    rvm gemset use $app
    echo "No se elimina crea gemset $app"
fi

# Crear aplicacion usando bd mysql/mariadb sin puma, usaremos thin y apache
# sin spring falla al usar vía bash
rails new $app -d mysql -P --skip-spring
echo "ruby-2.4.4" > "$app/.ruby-version"
echo "$app" > "$app/.ruby-gemset"
cd $app
# Aplicación básica creada

# Activar JavaScript V8
sed -i "s/# gem 'therubyracer', platforms: :ruby/gem 'therubyracer', platforms: :ruby/" Gemfile

echo "Javascript gema therubyracer ok"
# Agregar gemas
echo -e "\ngem 'activeadmin'\ngem 'activeadmin_addons'\n" >> Gemfile
echo -e "gem 'devise'\ngem 'devise-i18n'\n\ngem 'draper'\ngem 'kaminari'\ngem 'paper_trail'" >> Gemfile
echo -e "gem 'carrierwave'\ngem 'mini_magick'" >> Gemfile
echo "gemas agregadas"
bundle install
echo "Bundle ejecutado"

echo "Bundle terminado"
# Modificar config/database.yml
sed -i "s/password:$/password: $cmq/" config/database.yml
echo "config/database.yml modificado"

# Modificar config/application.rb
sed -i "12 s/config.load_defaults 5.1/config.load_defaults 5.1\n\n    config.i18n.default_locale = :es/" config/application.rb
echo "config/application.rb ...default_locale=es OK"/

# Modificar Inflector para español, como esta todo comentado, solo agregamos lineas al final
cd initializers
echo "ActiveSupport::Inflector.inflections(:en) do |inflect|" >> config/initializers/inflections.rb
echo "  inflect.plural(   /([aeo])$/i, '\1s'      )" >> config/initializers/inflections.rb
echo "  inflect.singular( /([aeo])s$/i, '\1'      )" >> config/initializers/inflections.rb
echo "  inflect.plural(   /([lnr])$/i, '\1es'     )" >> config/initializers/inflections.rb
echo "  inflect.singular( /([lnr])es$/i, '\1'     )" >> config/initializers/inflections.rb
echo "  inflect.irregular('version', 'versions'   )" >> config/initializers/inflections.rb
echo "end" >> config/initializers/inflections.rb 
echo "Inflector listo"

rails db:create
echo "Creación de BD ok"

# Preparara app/models/application_record.rb 
echo -e "\n  has_paper_trail\n" >> paso
echo -e "  def self.crear?(permiso, usuario)\n    permiso\n  end\n" >> paso
echo -e "  def self.leer?(permiso, usuario)\n    permiso\n  end\n" >> paso
echo -e "  def self.actualizar?(permiso, usuario)\n    permiso\n  end\n" >> paso
echo -e "  def self.eliminar(permiso, usuario)\n    permiso\n  end\n" >> paso
echo -e "  def crear?(permiso, usuario)\n    permiso\n  end\n" >> paso
echo -e "  def leer?(permiso, usuario)\n    permiso\n  end\n" >> paso
echo -e "  def actualizar?(permiso, usuario)\n    permiso\n  end\n" >> paso
echo -e "  def eliminar?(permiso, usuario)\n    permiso\n  end\n" >> paso
sed -i "2r paso" app/models/application_record.rb
echo "app/models/application_record.rb ok"
echo "application model permisos ok"

echo -e "\n  before_action :set_paper_trail_whodunnit\n\n" > paso
echo -e "  protected\n\n" >> paso
echo -e "  def user_for_paper_trail\n    usuario_signed_in? ? current_usuario&.id : 'NN'\n  end" >> paso
sed -i "2r paso" app/controllers/application_controller.rb
echo "app/controllers/application_controller.rb ok"

rails g paper_trail:install
rails g model Tabla nombre
rails g model Rol nombre nivel:integer
rails g uploader Foto
rails g model Region nombre titulo
rails g model Provincia nombre region:references
rails g model Comuna nombre provincia:references
wget https://raw.githubusercontent.com/ampinog/comunas/master/regiones.rb -O paso
sed -i "1r paso" db/migrate/*_create_regiones.rb
wget https://raw.githubusercontent.com/ampinog/comunas/master/provincias.csv -O db/provincias.csv
wget https://raw.githubusercontent.com/ampinog/comunas/master/provincias.rb -O paso
sed -i "1r paso" db/migrate/*_create_provincias.rb
wget https://raw.githubusercontent.com/ampinog/comunas/master/comunas.csv -O db/comunas.csv
wget https://raw.githubusercontent.com/ampinog/comunas/master/comunas.rb -O paso
sed -i "1r paso" db/migrate/*_create_comunas.rb

echo -e "\n  def migrate(dir)" > paso
echo      "    super" >> paso
echo      "    if dir == :up" >> paso
echo      "      Rol.create(nombre: 'Dios', nivel: 10000)" >> paso
echo      "    end" >> paso
echo      "  end">> paso
sed -i "1r paso" db/migrate/*_create_roles.rb 

echo -e "\n  def migrate(dir)" > paso
echo      "    super" >> paso
echo      "    if dir == :up" >> paso
echo      "      Tabla.create(nombre: 'Tabla')" >> paso
echo      "      Tabla.create(nombre: 'PaperTrail::Version')" >> paso
echo      "      Tabla.create(nombre: 'Rol')">> paso
echo      "      Tabla.create(nombre: 'RolesTabla')" >> paso
echo      "      Tabla.create(nombre: 'Usuario')" >> paso
echo      "      Tabla.create(nombre: 'ActiveAdmin::Comment')">> paso
echo      "      Tabla.create(nombre: 'Region')" >> paso
echo      "      Tabla.create(nombre: 'Provincia')" >> paso
echo      "      Tabla.create(nombre: 'Comuna')" >> paso
echo      "    end" >> paso
echo      "  end" >> paso
sed -i "1r paso" db/migrate/*_create_tablas.rb

rails g model RolesTabla rol:references tabla:references crear:boolean leer:boolean actualizar:boolean eliminar:boolean otro_sino:boolean otro

rails g active_admin:install Usuario
rails g activeadmin_addons:install
# Modifica nnnnnnnnnnnnn_devise_create_usuarios.rb
echo -e "\n  def migrate(dir)" > paso
echo "    super" >> paso
echo "    if dir == :up" >> paso
echo "      Usuario.create(nombre: 'prueba', email: 'prueba@prueba.cl'," >> paso
echo "        password: 'password', password_confirmation: 'password'," >> paso
echo "        rol_id: Rol.find_by(nombre: 'Dios').id)" >> paso
echo "    end" >> paso
echo "  end" >> paso
sed -i "3r paso" db/migrate/*_create_usuarios.rb
sed -i "19i\ \ \ \ \ \ t.string :nombre, null: false, default: '', limit: 20" db/migrate/*_create_usuarios.rb
sed -i "20i\ \ \ \ \ \ t.references :rol, index: true" db/migrate/*_create_usuarios.rb
sed -i "21i\ \ \ \ \ \ t.string :foto" db/migrate/*_create_usuarios.rb
sed -i "22i\ \ \ \ \ \ t.boolean :ver_filtro, default: true" db/migrate/*_create_usuarios.rb
# Activar Seguimiento/Conformacion/Bloqueo
sed -i "s/# t./t./g" db/migrate/*_create_usuarios.rb
sed -i "s/# add_index/add_index/g" db/migrate/*_create_usuarios.rb

echo -e "\n  def migrate(dir)" > paso
echo "    super" >> paso
echo "    if dir == :up" >> paso
echo "      rl=Rol.find_by(nombre: 'Dios')" >> paso
echo "      Tabla.all.each do |tbl|" >> paso
echo "        RolesTabla.create(rol_id: rl.id, tabla_id: tbl.id, crear: true, leer: true, actualizar: true, eliminar: true)" >> paso
echo "      end" >> paso
echo "    end" >> paso
echo -e "  end\n" >> paso
sed -i "1r paso" db/migrate/*_create_roles_tablas.rb
echo "Modificacion de migraciones OK"

rake db:migrate
# Traer local/es.yml
echo "traer locales"
wget https://raw.githubusercontent.com/svenfuchs/rails-i18n/master/rails/locale/es.yml -O config/locales/es.yml
wget https://raw.githubusercontent.com/activeadmin/activeadmin/master/config/locales/es.yml -O config/locales/activeadmin_es.yml
wget https://raw.githubusercontent.com/tigrish/kaminari-i18n/master/config/locales/es.yml -Oconfig/locales/kaminari_es.yml

# Crear activeadmin para Tablas / Roles /Rolestabla
echo "generators"
rails g active_admin:resource Tabla
rails g active_admin:resource Rol
rails g active_admin:resource Region
rails g active_admin:resource Provincia
rails g active_admin:resource Comuna
rails g decorator Usuario
rails g decorator Rol
rails g decorator Tabla
rails g decorator RolesTabla
rails g decorator Region
rails g decorator Provincia
rails g decorator Comuna

# Uploader
echo "Uploaders"
sed -i "4s/# //" app/uploaders/foto_uploader.rb
ln=$(sed -n "/Create different versions of your uploaded files:/=" app/uploaders/foto_uploader.rb)
ln=$(($ln + 1))
sed -i "${ln}d" app/uploaders/foto_uploader.rb
ln=$(($ln + 1))
sed -i "${ln}d" app/uploaders/foto_uploader.rb
ln=$(($ln + 1))
sed -i "${ln}d" app/uploaders/foto_uploader.rb
echo -e "  version :chica do\n    process resize_to_fit: [ 50, 50]\n  end\n" > paso
echo -e "  version :media do\n    process resize_to_fit: [100,100]\n  end" >> paso
ln=$(($ln - 1))
sed -i "${ln}r paso" app/uploaders/foto_uploader.rb
ln=$(sed -n "/  # def extension_whitelist/=" app/uploaders/foto_uploader.rb)
sed -i "${ln}s/# //" app/uploaders/foto_uploader.rb
ln=$(($ln + 1))
sed -i "${ln}s/# //" app/uploaders/foto_uploader.rb
ln=$(($ln + 1))
sed -i "${ln}s/# //" app/uploaders/foto_uploader.rb

# Admin
echo "Admin"
find app/admin/ -name "*.rb" -not -name "dashboard.rb" -type f -exec sed -i "2,13d" {} \;
echo -e "  decorate_with RolDecorator\n" > paso
echo "  permit_params :nombre, :nivel," >> paso
echo -e "    roles_tableas_attributes: [:id, :tabla_id, :clae, :otro_sino, :otro, :_destroy]\n" >> paso
echo -e "  menu label: 'Roles', parent: 'Administración', priority: 20\n" >> paso
echo "  index do" >> paso
echo "    column :nombre_" >> paso
echo "    column :nivel" >> paso
echo "    column :created_at" >> paso
echo "    column :updated_at" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  filter :nombre" >> paso
echo "  filter :nivel" >> paso
echo "" >> paso
echo "  show title: :nombre do" >> paso
echo "    attributes_table do" >> paso
echo "      row :nivel" >> paso
echo "      table_for rol.roles_tablas do" >> paso
echo "        column :tabla" >> paso
echo "        column :crear" >> paso
echo "        column :leer" >> paso
echo "        column :actualizar" >> paso
echo "        column :eliminar" >> paso
echo "        column :otro_sino" >> paso
echo "        column :otro" >> paso
echo "      end" >> paso
echo "    end" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  form do |f|" >> paso
echo "    f.inputs do" >> paso
echo "      f.input :nombre" >> paso
echo "      f.input :nivel" >> paso
echo "    end" >> paso
echo "    has_many :roles_tablas, new_record: 'Agregar tabla', allow_destroy: true, eading: 'Tablas' do |rota|" >> paso
echo "      rota.input :tabla" >> paso
echo "      rota.input :crear" >> paso
echo "      rota.input :leer" >> paso
echo "      rota.input :actualizar" >> paso
echo "      rota.input :eliminar" >> paso
echo "      rota.input :otro_sino" >> paso
echo "      rota.input :otro" >> paso
echo "    end" >> paso
echo "    f.actions" >> paso
echo "  end" >> paso
sed -i "2r paso" app/admin/roles.rb

echo -e "  decorate_with TablaDecorator\n" > paso
echo -e "  permit_params :nombre\n" >> paso
echo -e "  menu label: 'Tablas', parent: 'Administración', priority: 30\n" >> paso
echo "  index do" >> paso
echo "    column :nombre_" >> paso
echo "    column :created_at" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  filter :nombre" >> paso
echo "  filter :created_at" >> paso
echo "" >> paso
echo "  show title: :nombre do" >> paso
echo "    attributes_table do" >> paso
echo "      row :nombre" >> paso
echo "      row :created_at" >> paso
echo "      row :updated_at" >> paso
echo "    end" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  form do |f|" >> paso
echo "    f.inputs do" >> paso
echo "      f.input :nombre" >> paso
echo "    end" >> paso
echo "    actions" >> paso
echo "  end" >> paso
sed -i "1r paso" app/admin/tablas.rb

echo -e "  decorate_with UsuarioDecorator\n" > paso
echo -e "  permit_params :nombre, :email, :password, :password_confirmation, :foto\n" >> paso
echo -e "  menu label: 'Usuarios', parent: 'Administración', priority: 10\n" >> paso
echo "  index do" >> paso
echo "    column :nombre_" >> paso
echo "    column :email" >> paso
echo "    column :current_sign_in_at" >> paso
echo "    column :created_at" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  show tite: :nombre do" >> paso
echo "    attributes_table do" >> paso
echo "      if usuario.foto?" >> paso
echo "        row :foto do" >> paso
echo "          image_tag usuario.foto.chica.url" >> paso
echo "        end" >> paso
echo "      end" >> paso
echo "      row :email" >> paso
echo "      row :rol" >> paso
echo "      row :sign_in_count" >> paso
echo "      row :reset_password_sent_at" >> paso
echo "      row :remember_created_at" >> paso
echo "      row :sign_in_count" >> paso
echo "      row :current_sign_in_at" >> paso
echo "      row :last_sign_in_at" >> paso
echo "      row :current_sign_in_ip" >> paso
echo "      row :last_sign_in_ip" >> paso
echo "      row :confirmed_at" >> paso
echo "      row :confirmation_send_at" >> paso
echo "      row :locked_at" >> paso
echo "    end" >> paso
echo "    active_admin_comments" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  filter :nombre" >> paso
sed -i "1r paso" app/admin/usuarios.rb
ln=$(sed -n "/f.inputs do/=" app/admin/usuarios.rb)
ln=$(($ln + 1))
sed -i "${ln}i\ \ \ \ \ \ f.input :nombre" app/admin/usuarios.rb
ln=$(($ln + 2))
sed -i "${ln}i\ \ \ \ \ \ f.input :foto" app/admin/usuarios.rb

echo -e "  decorate_with RegionDecorator\n" > paso
echo -e "  permit_params :nombre, :titulo\n" >> paso
echo -e "  menu label: 'Regiones', parent: 'Tablas', priority: 10000\n" >> paso
echo "  index do" >> paso
echo "    column :nombre_" >> paso
echo "    column :titulo" >> paso
echo "  end" >> paso
echo ""
echo "  filter :nombre" >> paso
echo "  filter :titulo" >> paso
echo "" >> paso
sed -i "1r paso" app/admin/regiones.rb


echo -e "  decorate_with ProvinciaDecorator\n" > paso
echo -e "  permit_params :nombre, :region_id\n" >> paso
echo -e "  menu label: 'Provincia', parent: 'Tablas', priority: 9990\n" >> paso
echo "  index do" >> paso
echo "    column :nombre_" >> paso
echo "    column :region" >> paso
echo "  end" >> paso
echo ""
echo "  filter :nombre" >> paso
echo "  filter :region_id, as: :search_select_filter, display_name: 'titulo', fields: [:titulo], order_by: 'titulo_asc'" >> paso
echo "" >> paso
sed -i "1r paso" app/admin/provincias.rb

echo -e "  decorate_with ComunaDecorator\n" > paso
echo -e "  permit_params :nombre, :provincia\n" >> paso
echo -e "  menu label: 'Comunas', parent: 'Tablas', priority: 9980\n" >> paso
echo "  index do" >> paso
echo "    column :nombre_" >> paso
echo "    column :provincia" >> paso
echo "    column :region" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  filter :nombre" >> paso
echo "  filter :provincia_id, as: :search_select_filter, display_name: 'nombre', fields: [:nombre], order_by: 'nombre_asc'" >> paso
echo "  filter :region_id,    as: :search_select_filter, display_name: 'titulo', fields: [:titulo], order_by: 'titulo_asc'" >> paso
echo "" >> paso
sed -i "1r paso" app/admin/comunas.rb

# decorators
echo "Decorators"
# find app/decorators/ -name "*_decorator.rb" -type f -exec sed -i "4,12d" {};
sed -i "4,12d" app/decorators/*_decorator.rb
sed -i "4i\ \ def nombre_\n    h.link_to object.nombre, action: :show, id: object.id\n  end" app/decorators/rol_decorator.rb
sed -i "4i\ \ def nombre_\n    h.link_to object.nombre, action: :show, id: object.id\n  end" app/decorators/tabla_decorator.rb
sed -i "4i\ \ def nombre_\n    h.link_to object.nombre, action: :show, id: object.id\n  end" app/decorators/usuario_decorator.rb
sed -i "4i\ \ def nombre_\n    h.link_to object.nombre, action: :show, id: object.id\n  end" app/decorators/region_decorator.rb
sed -i "4i\ \ def nombre_\n    h.link_to object.nombre, action: :show, id: object.id\n  end" app/decorators/provincia_decorator.rb
sed -i "4i\ \ def nombre_\n    h.link_to object.nombre, action: :show, id: object.id\n  end" app/decorators/comuna_decorator.rb

# models
echo "Modelos"
# Rol
sed -i "2i\ \ has_many :roles_tablas" app/models/rol.rb
sed -i "3i\ \ has_many :usuarios\n" app/models/rol.rb
sed -i "5i \ \ accepts_nested_attributes_for :roles_tablas, allow_destroy: true" app/models/rol.rb
sed -i "2i\ " app/models/rol.rb
# Usuario
echo -e "\n  belongs_to :rol\n" > paso
echo "  mount_uploader :foto, FotoUploader" >> paso
echo "  def password_required?" >> paso
echo "    !persisted? || !password.blank? || !password_confirmation.blank?" >> paso
echo "  end" >> paso
sed -i "5r paso" app/models/usuario.rb
sed -Ei "s/(devise.*)$/\1 :confirmable, :lockable,/" app/models/usuario.rb
sed -Ei "s/(:recoverable.*)$/\1, :trackable/" app/models/usuario.rb
# Comuna
sed -Ei "s/(belongs_to :provincia)$/\1\n  has_one :region, through: :provincia/" app/models/comuna.rb
echo "Creación de tablas ok"

# Modificaciones en config/nitializers
echo "  config.namespace :admin do |admin|" > paso
echo "    admin.build_menu :default do |menu|" >> paso
echo "      menu.add label: 'Administración', priority: 10" >> paso
echo "      menu.add label: 'Tablas', priority: 1000" >> paso
echo "    end" >> paso
echo "    admin.build_menu :utility_navigation do |menu|" >> paso
echo "      menu.add label: ->{display_name current_usuario}," >> paso
echo "               url: ->{admin_usuario_path(current_usuario)}," >> paso
echo "               id: 'current_user'," >> paso
echo "               if: ->{current_active_admin_user?}" >> paso
echo "      admin.add_logout_button_to_menu menu" >> paso
echo "    end" >> paso
echo "  end" >> paso
echo -e "\n  config.comments_menu = { parent: 'Administración', priority: 1 }\n" >> paso
ln=$(sed -n "/# == Menu System/=" config/initializers/active_admin.rb)
sed -i "${ln}r paso" config/initializers/active_admin.rb
sed -i "s/config.localize_format = :long/config.localize_format = :mio/" config/initializers/active_admin.rb
sed -i "s/^end$/  config.display_name_methods = [:display_name, :full_name, :name, :nombre, :title, :to_s]\nend/" config/initializers/active_admin.rb
sed -i "s/config.batch_actions = true/config.batch_actions = false/" config/initializers/active_admin.rb

# Modificanso es.yml
ln=$(sed -n "/^  time:$/,/^      short:/=" config/locales/es.yml )
ln1=${ln: -3}
echo "ln1: $ln1"
sed -i "${ln1}i\ \ \ \ \ \ mio: '%d/%m/%Y %H:%M'" config/locales/es.yml

echo "*** FIN ***"
