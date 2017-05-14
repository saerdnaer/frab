class CallForParticipation < ApplicationRecord
  belongs_to :conference

  validates_presence_of :start_date, :end_date

  has_paper_trail

  def to_s
    "#{model_name.human}: #{conference.title}"
  end
end
