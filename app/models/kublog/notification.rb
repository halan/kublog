module Kublog
  class Notification < ActiveRecord::Base
    class Job < Struct.new(:notification_id)
      def perform
        Notification.find(notification_id).deliver!
      end
    end

    belongs_to :post
    serialize  :roles, Array
    delegate   :title, :url, :user, :to => :post

    validates_presence_of :kind
    validate do
      errors.add(:content, kind.to_sym) if content.blank?
    end

    after_create do
      Kublog.delay_notifications ? Delayed::Job.enqueue(Job.new(id)) : deliver!
      # Kublog.delay_notifications ? delay.deliver! : deliver!
    end
        
    def default?
      false
    end

    def email?
      kind == 'email'
    end

    def twitter?
      kind == 'twitter'
    end

    def facebook?
      kind == 'facebook'
    end

    def deliver!
      send "deliver_#{kind}!"
    end
    
    private
    def deliver_email!
      users = Kublog.notify_class.constantize.all
      users.each do |user|
        if user.notify_post? roles
          PostMailer.new_post(self, user).deliver
          increment :times_delivered
        end
      end
    end

    def deliver_twitter!
      Kublog.twitter_client.update [content, url].join(' ')
    end

    def deliver_facebook!
      Kublog.facebook_client.link! :link => url, :message => content
    end
  end
end
