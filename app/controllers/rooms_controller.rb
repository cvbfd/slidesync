class RoomsController < ApplicationController
  before_filter :require_login, except: :index
  protect_from_forgery except: :enter # accessed by pusher js library

  def index
    if params[:keyword].present?
      slideshare = Slideshare.search(params[:keyword])
      @slides = slideshare.slides
    else
      @slides = []
    end
  end

  def create
    begin
      if params[:slide_url].present?
        @slide = Slideshare.find_by_url(params[:slide_url])
      else
        @slide = Slideshare.find(params[:slide_id])
      end
      @room = current_user.rooms.create(
        slide_id: @slide.id,
        title: @slide.title,
        thumbnail: @slide.thumbnail,
        username: @slide.username,
        slide_url: @slide.doc,
        description: @slide.description
      )
      redirect_to @room
    rescue => e
      logger.error [e.class, e.message].join(' ')
      redirect_to :rooms, :error => e.message
    end
  end

  def show
    @room = Room.find(params[:id])
  end

  def update
    @room = current_user.rooms.find(params[:id])
    Pusher["presence-room-#{@room.id}"].trigger('jump_to', params[:page])
    head :ok
  end

  def destroy
    @room = current_user.rooms.find(params[:id])
    @room.destroy
    redirect_to :rooms
  end

  # POST /pusher/auth
  # returns JSON
  def enter
    if current_user
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id], {
        :user_id => current_user.id,
        :user_info => {
          :nickname => current_user.nickname,
          :icon_url => current_user.icon_url
        }
      })
      render :json => response
    else
      render text: 'Not authenticated'
    end
  end
end
