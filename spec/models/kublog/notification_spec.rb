require 'spec_helper'

describe Kublog::Notification do
  include Shoulda::ActiveRecord::Matchers

  before :all do
    Kublog.notify_class = 'User'
  end

  describe '#validate' do
    subject { Factory :notification }
    it { subject.should be_valid }
    it { should validate_presence_of :kind }
  end

  describe '#roles' do
    let(:notification) { Factory :notification, :roles => [:shipper, :carrier, :logistics] }

    it 'serializes roles into a hash or an array' do
      notification.reload
      notification.roles.should == [:shipper, :carrier, :logistics]
    end
  end
  
  describe '#title' do
    it 'delegates title to post' do
      @notification = Factory.build :notification, :post => Factory.build(:post)
      @notification.title.should == @notification.post.title
    end
  end
  
  describe '#url' do
    it 'delegates url to the post' do
      @notification = Factory.build :notification, :post => Factory.create(:post)
      @notification.url.should == @notification.post.url
    end
  end

  describe 'delivery timing' do
    let(:notification) { Factory.build :notification }

    it 'should deliver inmediatelly' do
      Kublog.delay_notifications.should be_false
      notification.should_receive :deliver!
      notification.save
    end

    it 'should delay delivery' do
      Kublog.delay_notifications = true
      notification.should_not_receive :deliver!
      Delayed::Job.should_receive :enqueue
      notification.save
    end
  end

  describe 'Email notification' do
    subject { Factory.build :email_notification, :post => Factory.build(:post, :user => Factory.build(:user)) }
    let(:notification) { subject }
    it { should validate_presence_of(:content).with_message("email message can't be blank") }
    it { notification.should be_valid }
    it { notification.should be_email }
    it { notification.should_not be_default }

    describe 'delivering' do
      let(:mock_mail) { mock(:deliver => true) }
      before do
        users = [mock(:notify_post? => true), mock(:notify_post? => true), mock(:notify_post? => false)]
        User.stub(:all).and_return(users)
        Kublog::PostMailer.stub(:new_post).and_return(mock_mail)
      end

      it 'increases the number of delivered times' do
        notification.times_delivered.should == 0
        notification.send(:deliver!)
        notification.times_delivered.should == 2
      end

      it 'sends e-mails to all users when notify_post? is true' do
        mock_mail.should_receive(:deliver).exactly(2).times
        notification.send(:deliver!)
      end
    end
  end

  describe 'Twitter notification' do
    subject { Factory.build :twitter_notification }
    let(:notification) { subject }
    it { should validate_presence_of(:content).with_message("twitter message can't be blank") }
    it { notification.should be_valid }
    it { notification.should be_twitter }
    it { notification.should_not be_default }

    describe 'delivering' do
      it 'should tweet' do
        notification.content  = 'Meow post!'
        notification.post.stub!(:url).and_return('http://example.com')
        Kublog.twitter_client.should_receive(:update).with "Meow post! http://example.com"
        notification.send(:deliver!)
      end
    end
  end

  describe 'Facebook notification' do
    subject { Factory.build :facebook_notification }
    let(:notification) { subject }
    it { should validate_presence_of(:content).with_message("facebook message can't be blank") }
    it { notification.should be_valid }
    it { notification.should be_facebook }
    it { notification.should_not be_default }

    describe 'delivering' do
      it 'should post to wall' do
        notification.content = 'Meow post!'
        notification.post.stub!(:url).and_return('http://example.com')
        Kublog.facebook_client.should_receive(:link!).with :message => "Meow post!", :link => 'http://example.com'
        notification.send(:deliver!)
      end
    end
  end
end
