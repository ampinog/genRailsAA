#!/bin/bash --login
es_numero='^-?[0-9]+([.][0-9]+)?$'
es_nombre='^[a-zA_Z]+[a-zA_Z0-9_-]+$'
app=$1
cmq=$2
gem=$3
if test $app = ? -o $app = help  ; then
  echo "Prametros"
  echo "========="
  echo "1.- Nombre de aplicación."
  echo "2.- Password para acceder a BD."
  echo "3.- S/N elimina y recrea gemset."
  echo "    gemset usa nombre de aplicación"
  echo "---------------------------------------"
  exit 0
fi
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

# Modificar config/database.yml
sed -i "s/password:$/password: $cmq/" config/database.yml
echo "config/database.yml modificado"

# Modificar config/application.rb
sed -i "12 s/config.load_defaults 5.1/config.load_defaults 5.1\n\n    config.i18n.default_locale = :es/" config/application.rb
echo "config/application.rb ...default_locale=es OK"/

# Modificar Inflector para español, como esta todo comentado, solo agregamos lineas al final
cd initializers
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/config/initializers/inflections.rb -O config/initializers/inflectios.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/config/initializers/setup_mail.rb -O config/initializers/setup_mail.rb

# lib
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/lib/development_mail_interceptor.rb -O lib/development_mail_interceptor.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/lib/milib.rb -O lib/milib.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/lib/active_admin_views_pages_base.rb -O lib/active_admin_views_pages_base.rb

rails db:create
echo "Creación de BD ok"

# Preparara app/models/application_record.rb 
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/models/application_record.rb -O app/models/application_record.rb

rails g paper_trail:install
rails g model Tabla nombre
rails g model Rol nombre nivel:integer
rails g uploader Foto
rails g model Region nombre titulo
rails g model Provincia nombre region:references
rails g model Comuna nombre provincia:references


wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/controllers/application_controller.rb -O app/controllers/application_controller.rb
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
# Activar Seguimiento/Confirmacion/Bloqueo
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

# Crear activeadmi
echo "generators"
rails g active_admin:resource Tabla
rails g active_admin:resource Rol
rails g active_admin:resource Region
rails g active_admin:resource Provincia
rails g active_admin:resource Comuna
# Crear Decorators 
rails g decorator Usuario
rails g decorator Rol
rails g decorator Tabla
rails g decorator RolesTabla
rails g decorator Region
rails g decorator Provincia
rails g decorator Comuna

# UPLOADER
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/uploaders/foto_uploader.rb -O app/uploaders/foto_uploader.rb

# ADMIN
echo "Admin"
find app/admin/ -name "*.rb" -not -name "dashboard.rb" -type f -exec sed -i "2,13d" {} \;
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/admin/roles.rb -O app/admin/roles.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/admin/usuarios.rb -O app/admin/usuarios.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/admin/regiones.rb -O app/admin/regiones.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/admin/provincias.rb -O app/admin/provincias.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/admin/comunas.rb -O app/admin/comunas.rb

# DECORATORS
echo "Decorators"
# find app/decorators/ -name "*_decorator.rb" -type f -exec sed -i "4,12d" {};
sed -i "4,12d" app/decorators/*_decorator.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/decorators/comuna_decorator.rb -O app/decorators/comuna_decorator.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/decorators/provincia_decorators.rb -O app/decorators/provincia_decorator.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/decorators/region_decorator.rb -O app/decorators/region_decorator.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/decorators/rol_decorator.rb -O app/decorators/rol_decorator.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/decorators/tabla_decorator.rb -O app/decorators/tabla_decorator.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/decorators/usuario_decorator.rb -O app/decorators/usuario_decorator.rb

# MODELS
echo "Modelos"
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/models/rol.rb -O app/models/rol.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/models/usuario.rb -O app/models/usuario.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/models/comuna.rb -O app/models/comuna.rb
wget https://raw.githubusercontent.com/ampinog/genRailsAA/master/app/models/provincia.rb -O app/models/provincia.rb
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
