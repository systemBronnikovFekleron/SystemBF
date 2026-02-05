# frozen_string_literal: true

module Admin
  class WikiPagesController < Admin::BaseController
    before_action :set_wiki_page, only: [:show, :edit, :update, :destroy]

    def index
      @root_pages = WikiPage.root_pages.ordered.includes(:children, :created_by)
      @total_count = WikiPage.count
      @published_count = WikiPage.status_published.count
      @draft_count = WikiPage.status_draft.count
    end

    def show
      @children = @wiki_page.children.ordered
    end

    def new
      @wiki_page = WikiPage.new
      @wiki_page.parent_id = params[:parent_id] if params[:parent_id]
      @parent_pages = WikiPage.published.ordered
    end

    def create
      @wiki_page = WikiPage.new(wiki_page_params)
      @wiki_page.created_by = current_user
      @wiki_page.updated_by = current_user

      if @wiki_page.save
        redirect_to admin_wiki_page_path(@wiki_page), notice: 'WIKI страница успешно создана'
      else
        @parent_pages = WikiPage.published.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @parent_pages = WikiPage.where.not(id: @wiki_page.id).ordered
    end

    def update
      @wiki_page.updated_by = current_user

      if @wiki_page.update(wiki_page_params)
        redirect_to admin_wiki_page_path(@wiki_page), notice: 'WIKI страница успешно обновлена'
      else
        @parent_pages = WikiPage.where.not(id: @wiki_page.id).ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @wiki_page.has_children?
        redirect_to admin_wiki_pages_path, alert: "Невозможно удалить страницу с подстраницами (#{@wiki_page.children.count})"
      else
        @wiki_page.destroy
        redirect_to admin_wiki_pages_path, notice: 'WIKI страница удалена'
      end
    end

    def reorder
      params[:pages].each_with_index do |id, index|
        WikiPage.find(id).update(position: index + 1)
      end
      head :ok
    end

    private

    def set_wiki_page
      @wiki_page = WikiPage.friendly.find(params[:id])
    end

    def wiki_page_params
      params.require(:wiki_page).permit(:title, :slug, :content, :parent_id, :position, :status)
    end
  end
end
