class ArchivesController < ApplicationController
  def home
    @body_id = "home"
    @homepage = true

    # feed
    @articles = Article.live.published.limit(7).root.to_a

    # pinned article
    pinned_to_home_bottom_page_id = setting(:pinned_to_home_bottom_page_id)
    if pinned_to_home_bottom_page_id.present?
      @pinned_to_home_bottom = Page.find(pinned_to_home_bottom_page_id)
    end
  end

  def index
    @body_id     = "archives"
    @articles = {}

    Article.unpinned.published.feed.all.each do |article|
      year  = article.published_at.year
      month = article.published_at.month

      @articles[year]        = {} if @articles[year].nil?
      @articles[year][month] = [] if @articles[year][month].nil?

      @articles[year][month] << article
    end
  end
end
