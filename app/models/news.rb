class News < ApplicationRecord
  TARGET_AUDIENCES = %w(everyone collaborators customers).freeze

  validates_presence_of :title, :body
  validates_inclusion_of :target_audience, in: TARGET_AUDIENCES

  scope :published, -> { where.not(published_at: nil) }

  state_machine initial: :created do
    state :created
    state :published

    before_transition created: :published do |news, _transition|
      news.published_at = Time.now
    end

    event :publish do
      transition created: :published
    end
  end

  def self.search(contains)
    news = self.all
    news = news.where(target_audience: contains[:target_audience]) if contains[:target_audience].present?
    news = news.where("title LIKE ?", "%#{contains[:title]}%") if contains[:title].present?

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        news = news.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    if contains[:updated_at]
      contains[:updated_at].each do |operator, value|
        news = news.where("updated_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    if contains[:published_at]
      contains[:published_at].each do |operator, value|
        news = news.where("published_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    news
  end

  def body=(content)
    super ActionController::Base.helpers.sanitize(content, tags: allowed_tags, attributes: allowed_attributes)
  end

  private

  def allowed_tags
    ActionView::Base.sanitized_allowed_tags + %w(u s)
  end

  def allowed_attributes
    ActionView::Base.sanitized_allowed_attributes + %w(style)
  end
end
