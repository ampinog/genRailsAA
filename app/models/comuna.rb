class Comuna < ApplicationRecord
  belongs_to :provincia
  has_one :region, through: :provincia
end
