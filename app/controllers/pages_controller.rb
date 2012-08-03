# -*- encoding : UTF-8 -*-
class PagesController < ApplicationController

  before_filter :load_resource, :only => %w(show)

protected

  def load_resource
    @page = Page.find_by_slug params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Page, params[:id]) if @page.nil?
    @pages = Page.where(tag: @page.tag).visible.by_position
  end

public

  def show
  end
end
