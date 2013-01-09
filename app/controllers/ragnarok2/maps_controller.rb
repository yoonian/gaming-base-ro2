require_dependency "ragnarok2/application_controller"

module Ragnarok2
  class MapsController < ApplicationController

    def index
      if params[:q].nil? || params[:q].length.zero?
        @maps = Map.default_order.page(params[:page])
      else
        @maps = Map.default_order.where("ragnarok2_maps.name LIKE ?", "%#{params[:q]}%").page(params[:page])
      end
      respond_with(@maps)
    end

    def show
      respond_with(@map = Map.find(params[:id]))
    end

  end
end
