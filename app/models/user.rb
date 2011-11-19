# encoding: utf-8
class User < ActiveRecord::Base
  
  scope :by_name, order('name ASC')
  
  has_secure_password
  validates :password, :presence => { :on => :create }
  has_many :punches

  def working?
    if last_punch = self.punches.order('punched_at DESC').first
      last_punch.entrance?
    else
      false
    end
  end

  def hours_since_last_state
    if last_punch = self.punches.order('punched_at DESC').first
      (Time.now - last_punch.punched_at)/60/60
    else
      0
    end
  end
  
  def hours_worked(datetime_range)
    punches_in_range = self.punches.where('punched_at >= ? and punched_at <= ?', datetime_range.begin, datetime_range.end).order('punched_at ASC').all
    
    return 0 if punches_in_range.empty?
    
    #add punches to the edges, if appropriate
    if not punches_in_range.first.entrance?
      punches_in_range.unshift self.punches.new(:punched_at => datetime_range.begin)
    end
    if punches_in_range.last.entrance?
      punches_in_range << self.punches.new(:punched_at => datetime_range.end)
    end
    
    time_worked = 0
    punches_in_range.each_cons(2) do |pair|
      time_worked += pair.last.punched_at - pair.first.punched_at
    end
    
    time_worked/60/60
  end
  
end
