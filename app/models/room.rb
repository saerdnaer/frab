class Room < ApplicationRecord
  belongs_to :conference
  has_many :events

  has_paper_trail meta: { associated_id: :conference_id, associated_type: 'Conference' }

  default_scope -> { order(:rank) }

  def to_s
    "#{model_name.human}: #{self.name}"
  end
end
