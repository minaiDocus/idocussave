# frozen_string_literal: true

class Admin::NewsController < Admin::AdminController
  before_action :load_news, except: %w[index new create]

  def index
    @news = News.search(search_terms(params[:news_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def show; end

  def new
    @news = News.new
  end

  def create
    @news = News.new(news_params)
    if @news.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_news_path(@news)
    else
      render :new
    end
  end

  def edit; end

  def update
    if @news.update(news_params)
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_news_path(@news)
    else
      render :edit
    end
  end

  def destroy
    @news.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_news_index_path
  end

  def publish
    @news.publish
    flash[:notice] = "L'annonce \"#{@news.title}\" a été publié."
    redirect_to admin_news_path(@news)
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def load_news
    @news = News.find params[:id]
  end

  def news_params
    params.require(:news).permit(:title, :body, :url, :target_audience)
  end
end
