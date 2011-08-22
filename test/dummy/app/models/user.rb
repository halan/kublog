class User < ActiveRecord::Base
  include Kublog::Notifiable
  
  #TODO: Should be included into a helper
  has_many              :posts, :class_name => 'Kublog::Post' 
  
  has_secure_password
  validates_presence_of :email
  validates_presence_of :password
  
  def to_s
    email
  end
  
  def notify_post?(post)
    if post.for_shipper?
      return self.email == 'adrian@rutanet.com'
    else
      return true
    end
  end
  
  def admin?
    true
  end
  
end
