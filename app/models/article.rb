class Article < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :status
  belongs_to :theme

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :collection_posts, foreign_key: :collection_id, class_name: :Article
  belongs_to :collection, foreign_key: :collection_id, class_name: :Article

  scope :draft,       -> { where(status: Status.find_by(name: "draft")) }
  scope :edited,      -> { where(status: Status.find_by(name: "edited")) }
  scope :designed,    -> { where(status: Status.find_by(name: "designed")) }
  scope :published,   -> { where(status: Status.find_by(name: "published")) }

  scope :live,        -> { where("published_at < ?", Time.now) }

  scope :chronological, -> { order(published_at: :desc) }

  scope :root, -> { where(collection_id: nil) }

  before_validation :generate_slug,            on: [:create, :update]
  before_validation :generate_published_dates, on: [:create, :update]
  before_validation :generate_draft_code,      on: [:create, :update]

  default_scope { order("published_at DESC") }
  scope :on, lambda { |date| where("published_at BETWEEN ? AND ?", date.try(:beginning_of_day), date.try(:end_of_day)) }

  def name
    if title.present? && subtitle.present?
      "#{title} : #{subtitle}"
    else
      title
    end
  end

  def path
    if published?
      published_at.strftime("/%Y/%m/%d/#{slug}")
    else
      "/drafts/articles/#{self.draft_code}"
    end
  end

  def slug_exists?
    Article.on(published_at).where(slug: slug).exists?
  end

  def save_tags!(tags_glob)
    self.taggings.destroy_all

    tags_glob.split(",").each do |name|
      unless name.blank?
        tag = Tag.find_or_create_by(name: name)
        self.tags << tag
      end
    end
  end

  def save_categories!(categories_glob)
    self.categorizations.destroy_all

    categories_glob.split(",").each do |name|
      unless name.blank?
        category = Category.find_or_create_by(name: name)
        self.categories << category
      end
    end
  end

  # article states through the process from creation to publishing
  def draft?
    status.name == "draft"
  end

  def edited?
    status.name == "edited"
  end

  def designed?
    status.name == "designed"
  end

  def published?
    status.name == "published"
  end

  def dated?
    published_at.present?
  end

  def collection_root?
    collection_posts.any?
  end

  def in_collection?
    collection.present?
  end

  private

  def generate_slug
    if self.new_record? || self.slug_changed? || self.slug.blank?
      n = 0

      if slug.blank?
        self.slug = self.name.to_slug
      end

      while slug_exists?
        self.slug = name
        n += 1
        "#{self.slug} #{n}".to_slug
      end
    end

    self.slug = self.slug.to_slug
  end

  def generate_published_dates
    if published_at.present?
      self.year  = published_at.year                     if published_at.year.present?
      self.month = published_at.month.to_s.rjust(2, "0") if published_at.month.present?
      self.day   = published_at.day.to_s.rjust(2, "0")   if published_at.day.present?
    end
  end

  def generate_draft_code
    self.draft_code ||= SecureRandom.hex
  end
end
