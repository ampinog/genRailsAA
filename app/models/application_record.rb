class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  has_paper_trail

  def self.crear?(permiso, usuario)
    permiso
  end

  def self.leer?(permiso, usuario)
    permiso
  end

  def self.actualizar?(permiso, usuario)
    permiso
  end

  def self.eliminar(permiso, usuario)
    permiso
  end

  def crear?(permiso, usuario)
    permiso
  end

  def leer?(permiso, usuario)
    permiso
  end

  def actualizar?(permiso, usuario)
    permiso
  end

  def eliminar?(permiso, usuario)
    permiso
  end

end
