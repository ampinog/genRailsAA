class Rol < ApplicationRecord
 
  has_many :roles_tablas
  has_many :usuarios

  accepts_nested_attributes_for :roles_tablas, allow_destroy: true

  def name
    self.nombre
  end
end
