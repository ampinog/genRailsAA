#!/bin/bash --login

function contiene() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

es_nombre='^[A-Z]+[a-zA-Z]+$'
accion=$1
if [[ $accion =~ '^[^gd]$' ]] ; then
  echo "ERROR Primer arumento debe ser g/d!." >&2; exit 1
fi
tabla=$2
if ! [[ $tabla =~ $es_nombre ]] ; then
  echo "ERROR Primer argumento($tabla): No es un nombre de tabla(Clase) valido" >&2; exit 2
fi
if [[ $# == 1 ]] ; then
  echo "ERROR: debe indicar algunos campos para la tabla" >&2; exit 3
fi

referencias=()
parametros=()
modificadores=()
prms_txt=""
contador=0
for i in "$@"
do
  if (( contador > 1 )) ; then
    if [[ $i =~ '{' ]] ; then
      paso=${i##*\{}
      paso=${paso%\}*}
      modificadores+=("$paso")
      parametro=${i%\{*}
      if [[ $i =~ ':references{' ]] ; then
        referencias+=("R")
      else
        referencias+=("N")
      fi
    else
      modificadores+=("")
      referencias+=("N")
      parametro=$i
    fi
    # Para generar la migración
    prms_txt="$prms_txt$parametro "
    if [[ $parametro =~ ':' ]]; then
      parametros+=(${parametro%\:*})
    else
      parametros+=($parametro)
    fi
  fi
  let contador=$contador+1
done

echo "************************************************"
echo "Nro: Parametro -> Ref -> modif"

for (( ind=0; ind<${#modificadores[@]}; ind++ ))
do
  echo "$((ind + 1)): ${parametros[ind]} -> ${referencias[ind]} -> ${modificadores[ind]}'"
done
echo ""
echo "Eliminación previa"
echo "rails d active_admin:resource $tabla"
rails d active_admin:resource $tabla
echo "rails d decorator $tabla"
rails d decorator $tabla
echo "rails d model $tabla"
rails d model $tabla
if [ "$accion" == "d" ]; then
  # Si es solo eliminación
  echo "Eliminacion lista." >&2; exit 0
fi
echo ""
tbls=$(rails runner "puts '$tabla'.tableize")
tbl=$(rails  runner "puts '$tabla'.underscore")
echo "Tabla: $tbls (plural)"
echo "Under: $tbl  (singular)"
echo ""
echo "Creando Modelo"
echo "rails g model $tabla $prms_txt"
rails g model $tabla $prms_txt
echo "rails g active_admin:resource $tabla"
rails g active_admin:resource $tabla
echo "rails g decorator $tabla"
rails g decorator $tabla

# db/migrate/*_create_${tbls}.rb
echo "Modificando migracion"
echo "modificando migración, agregando modificadores"
for (( ind=0; ind<${#modificadores[@]}; ind++ ))
do
  ln=$(sed -n "/${parametros[ind]}/=" db/migrate/*_create_${tbls}.rb)
  echo "'${parametros[ind]}' -> linea: $ln -> ${modificadores[ind]}"
  if [[ ! -z ${modificadores[ind]} ]] ; then
    echo "Sí agrego modificador ${modificador[ind]}"
    if [[ ${referencias[ind]} == "R" ]] ; then
      echo "con referencia ${referencia[ind]}"
      sed -i "${ln} s/true *$/\{ ${modificadores[ind]}\}/" db/migrate/*_create_${tbls}.rb
    else
      echo "sin referencia ${referencia[ind]}"
      sed -i "${ln} s/$/, ${modificadores[ind]}/" db/migrate/*_create_${tbls}.rb
    fi
  fi
done
echo ""
echo "Agregando a Tablas y Rol Dios"
echo -e "\n  def migrate( dir)" > paso
echo "    super" >> paso
echo "    rol = Rol.find_by_nombre('Dios')" >> paso
echo "    if dir == :up" >> paso
echo "      tbl = Tabla.create(nombre: '$tbl')" >> paso
echo "      rol.roles_tablas.create(tabla_id: tbl.id," >> paso
echo "        crear: true, leer: true, actualizar: true, eliminar: true)" >> paso
echo "    else" >> paso
echo "      if (tbl = Tabla.find_by(nombre: '$tbl'))" >> paso
echo "        RolesTabla.find_by(rol_id: rol.id, tabla_id: tbl.id)&.destroy" >> paso
echo "        tbl.destroy" >> paso
echo "      end" >> paso
echo "    end" >> paso
echo "  end" >> paso
echo "" >> paso
sed -i "1r paso" db/migrate/*_create_${tbls}.rb
echo "***************** OJO se hara un rails db:migrate:reset RAILS_ENV=development ***********"
rails db:environment:set RAILS_ENV=development
rails db:migrate:reset RAILS_ENV=development

# exit

# app/decorators/${tbl}_decorator.rb
sed -i "4,11d" app/decorators/${tbl}_decorator.rb
# Si existe nombre en los parametros
# no existe nombre, usar primer parametro
if [ $(contiene "parametros[@]" "nombre") ]; then
  sed -i "4i\ \ def nombre_\n    h.link_to object.nombre, action: :show, id: object.id\n  end\n" app/decorators/${tbl}_decorator.rb
else
  sed -i "4i\ \ def ${parametros[0]}_\n    h.link_to object.${parametros[0]}, action: :show, id: object.id\n  end\n" app/decorators/${tbl}_decorator.rb
fi

# app/admin/${tbls}.rb
# prepara lista de parametros
prm_pto=""
for i in "${parametros[@]}"
do
  if [[ ${referencias[ind]} == "R" ]] ; then
    al_final="_id"
  else
    al_final=""
  fi
  if [[ -z $prm_pto ]] ; then
    prm_pto=":${i}${al_final}"
  else
    prm_pto="${prm_pto}, :${i}${al_final}"
  fi
done
echo "parm_pto: ${prm_pto}"
echo ""
echo "Elimina 2-13 lineas de admn/${tbls}.rb"
sed -i "2,13d" app/admin/${tbls}.rb
echo -e "  decorate_with ${tabla}Decorator\n" > paso
echo "  permit_params ${prm_pto}" >> paso
echo "" >> paso
echo "  index do" >> paso
for i in "${parametros[@]}"
do
  if [ "$i" == "${parametros[0]}" ]; then
    echo "    column :${i}_" >> paso
  else
    echo "    column :${i}" >> paso
  fi
done
echo "  end" >> paso
echo "" >> paso
for i in "${parametros[@]}"
do
  echo "  filter :${i}" >> paso
done
echo "" >> paso
echo "  show do" >> paso
echo "    attributes_table do" >> paso
for i in "${parametros[@]}"
do
  echo "      row :${i}" >> paso
done
echo "    end" >> paso
echo "    active_admin_comments" >> paso
echo "  end" >> paso
echo "" >> paso
echo "  form do |f|" >> paso
echo "    f.inputs do " >> paso
for i in "${parametros[@]}"
do
  echo "      f.input :${i}" >> paso
done
echo "    end" >> paso
echo "    f.actions" >> paso
echo "  end" >> paso
echo " Modificacion final de admin/${tbls}.rb"
sed -i "2r paso" app/admin/${tbls}.rb

