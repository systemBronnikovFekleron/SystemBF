# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::BaseController
    before_action :set_article, only: [:show, :edit, :update, :destroy]

    def index
      @articles = Article.includes(:author).ordered

      # Фильтры
      @articles = @articles.where(article_type: params[:type]) if params[:type].present?
      @articles = @articles.where(status: params[:status]) if params[:status].present?
      @articles = @articles.where(featured: true) if params[:featured] == 'true'

      @articles = @articles.page(params[:page]).per(20)

      # Stats
      @total_count = Article.count
      @published_count = Article.status_published.count
      @draft_count = Article.status_draft.count
    end

    def show
      # Preview article
    end

    def new
      @article = Article.new
    end

    def create
      @article = Article.new(article_params)
      @article.author = current_user

      if @article.save
        redirect_to admin_article_path(@article), notice: 'Статья успешно создана'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @article.update(article_params)
        redirect_to admin_article_path(@article), notice: 'Статья успешно обновлена'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy
      redirect_to admin_articles_path, notice: 'Статья удалена'
    end

    def bulk_action
      action = params[:bulk_action]
      article_ids = params[:article_ids] || []

      case action
      when 'publish'
        Article.where(id: article_ids).update_all(status: :published, published_at: Time.current)
        message = "#{article_ids.count} статей опубликовано"
      when 'archive'
        Article.where(id: article_ids).update_all(status: :archived)
        message = "#{article_ids.count} статей архивировано"
      when 'draft'
        Article.where(id: article_ids).update_all(status: :draft, published_at: nil)
        message = "#{article_ids.count} статей переведено в черновики"
      when 'delete'
        Article.where(id: article_ids).destroy_all
        message = "#{article_ids.count} статей удалено"
      when 'feature'
        Article.where(id: article_ids).update_all(featured: true)
        message = "#{article_ids.count} статей отмечено как избранные"
      when 'unfeature'
        Article.where(id: article_ids).update_all(featured: false)
        message = "#{article_ids.count} статей убрано из избранных"
      else
        message = 'Неизвестное действие'
      end

      redirect_to admin_articles_path, notice: message
    end

    private

    def set_article
      @article = Article.friendly.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :title, :slug, :excerpt, :content, :article_type,
        :status, :featured, :published_at
      )
    end
  end
end
