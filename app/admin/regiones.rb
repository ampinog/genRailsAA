ActiveAdmin.register Region do                                     
  decorate_with RegionDecorator                                    

  permit_params :nombre, :titulo                                   
                                                                   
  menu label: 'Regiones', parent: 'Tablas', priority: 10000        

  index do
    column :nombre_
    column :titulo
  end                                                              
  filter :nombre
  filter :titulo

  action_item :ocultar_ver_side_bar, only: :index do
    link_to "Ocultar/Ver filtro","#", {id: 'ocultar_ver_side_bar'}
  end
end
