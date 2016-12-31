class ArticlesController < ApplicationController
  def index
    @body_id    = "articles"
    @page_title = "Articles"

    @articles_year  = params[:year]
    @articles_month = params[:month]
    @articles_day   = params[:day]

    @articles = Article.published.root
    #TODO add this after pagination setup:
    # .paginate(per_page: 5, page: params[:page])

    @articles = @articles.where(year:  params[:year])  if params[:year]
    @articles = @articles.where(month: params[:month]) if params[:month]
    @articles = @articles.where(day:   params[:day])   if params[:day]

    if @articles.length == 1
      return redirect_to @articles.first.path
    end
  end

  def show
    @body_id = "article"

    # get the article
    if request.path =~ /^\/drafts/
      @article = Article.find_by(draft_code: params[:draft_code])

      if @article.published?
        return redirect_to(@article.path)
      end

      @collection_posts = @article.collection_posts.chronological

    else
      @article = Article.where(year:  params[:year]
                       ).where(month: params[:month]
                       ).where(day:   params[:day]
                       ).where(slug:  params[:slug]).first
      @collection_posts = @article.collection_posts.published.live.chronological
    end

    # no article found, go to /articles feed
    article_redirects


    @title = @article.name


    if @article.hide_layout?
      render html: @article.content.html_safe, layout: false
    else
      render "articles/show"
    end
  end

  def article_redirects
    if @article.nil?
      return redirect_to root_path
    end

    if @article.published? && params[:draft_code].present?
      return redirect_to @article.path
    end
  end
end
