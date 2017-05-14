class Link < ApplicationRecord
  belongs_to :linkable, polymorphic: true

  validates_presence_of :title, :url

  has_paper_trail meta: {
    associated_id: :linkable_id,
    associated_type: :linkable_type
  }

  def to_s
    "#{model_name.human}: #{title}"
  end
end
