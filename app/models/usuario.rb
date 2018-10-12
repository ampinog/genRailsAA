class Usuario < ApplicationRecord
  # Include default devise modules. Others available are: :confirmable, :lockable,
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,  :confirmable, :lockable,
         :recoverable, :rememberable, :validatable, :trackable

  belongs_to :rol

  mount_uploader :foto, FotoUploader
  def password_required?
    !persisted? || !password.blank? || !password_confirmation.blank?
  end
end
