module Kublog
  class PostMailer < ActionMailer::Base
        
    def new_post(notification, user)
      @notification, @user = notification, user
      mail :to => @user.email, :subject => @notification.title, :from => Kublog.email_from(@notification)
    end
  end
end
