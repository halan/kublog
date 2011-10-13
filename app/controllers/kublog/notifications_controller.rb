module Kublog
  class NotificationsController < ApplicationController
    
    def preview
      @post    = Post.new(params[:post])
      @preview = render_to_string 'kublog/post_mailer/default_template', :layout => false
      respond_to do |format|
        format.json { render :json => {:preview => @preview} }
      end
    end
  end
end
