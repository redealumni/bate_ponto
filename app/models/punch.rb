# encoding: utf-8
class Punch < ActiveRecord::Base
  
  belongs_to :user
  
  validates_presence_of :user

  before_validation do
    self.punched_at ||= Time.now
  end
  
  before_save do
    if self.user
      last_punch_scope = self.user.punches.order("punched_at DESC").where('punched_at < ?', self.punched_at)
      last_punch_scope = last_punch_scope.where('id <> ?', self.id) unless self.new_record?
      last_punch = last_punch_scope.first
      self.entrance = last_punch ? !last_punch.entrance? : true
    end
    true
  end
    
  scope :latest, order('punched_at DESC')
  
  def entrance?
    if self.new_record? and self.user
      last_punch = self.user.punches.order("punched_at DESC").first
      self.entrance = !last_punch.entrance? if last_punch
    end
    !!self.entrance    
  end
  
  def exit?
    !entrance?
  end

end
