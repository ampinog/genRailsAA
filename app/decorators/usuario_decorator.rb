class UsuarioDecorator < Draper::Decorator
  delegate_all

  def nombre_
    h.link_to object.nombre, action: :show, id: object.id
  end
end 
