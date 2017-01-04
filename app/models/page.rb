class Page < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :status

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations

  scope :draft,       -> { where(status: Status.find_by(name: "draft")) }
  scope :edited,      -> { where(status: Status.find_by(name: "edited")) }
  scope :designed,    -> { where(status: Status.find_by(name: "designed")) }
  scope :published,   -> { where(status: Status.find_by(name: "published")) }

  before_validation :generate_slug,            on: [:create, :update]
  before_validation :generate_draft_code,      on: [:create, :update]

  default_scope { order("published_at DESC") }

  def name
    if title.present? && subtitle.present?
      "#{title} : #{subtitle}"
    else
      title
    end
  end

  def path
    if self.published?
      "/#{self.slug}"
    else
      "/drafts/pages/#{self.draft_code}"
    end
  end

  def content_rendered
    Kramdown::Document.new(
      content,
      input: content_format == "html" ? :html : :kramdown,
      remove_block_html_tags: false,
      transliterated_header_ids: true,
      html_to_native: true
    ).to_html.html_safe
  end

  def slug_exists?
    Page.where(slug: slug).exists?
  end

  # page states through the process from creation to publishing
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

  def meta_description
    if summary.blank?
      html = Kramdown::Document.new(
        content,
        input: :kramdown,
        remove_block_html_tags: false,
        transliterated_header_ids: true
      ).to_html.to_s

      doc = Nokogiri::HTML(html)
      doc.css("body").text.truncate(200)
    else
      summary
    end
  end

  private

  def slug_exists?
    Page.where(slug: slug).exists?
  end

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

  def generate_draft_code
    self.draft_code ||= SecureRandom.hex
  end
end
