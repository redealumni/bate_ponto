class Punch < ActiveRecord::Base

  belongs_to :user

  validates :user, presence: true

  before_validation do
    self.punched_at ||= Time.zone.now
  end

  before_save do
    if self.user
      last_punch_scope = self.user.punches.latest.where('punched_at < ?', self.punched_at)
      last_punch_scope = last_punch_scope.where('id <> ?', self.id) unless self.new_record?
      last_punch = last_punch_scope.first
      self.entrance = last_punch ? !last_punch.entrance? : true
    end
    true
  end

  after_save do
    if self.entrance?
      self.fix_punch
    end
  end

  scope :latest, -> { order 'punched_at DESC' }

  def is_punch_time_ok(day, shift_num, moment)
    self.user.is_punch_time_ok self.punched_at, day, shift_num, moment
  end

  # Return as a integer in minutes
  def punch_time_error(day, shift_num, moment)
    self.user.punch_time_error self.punched_at, day, shift_num, moment
  end

  def entrance?
    if self.new_record? and self.user
      last_punch = self.user.punches.latest.first
      self.entrance = !last_punch.entrance? if last_punch
    end
    !!self.entrance
  end

  def exit?
    !entrance?
  end

  def altered?
    (self.punched_at - self.created_at).abs > 15.minutes
  end

  def fix_punch
    after = self.user.punches.latest.where("punched_at > ?", self.punched_at)
    if after.blank?
      self.user.punches.create(punched_at: self.punched_at + 6.hours, 
        comment: "Batida automática feita as #{Time.zone.now}, favor corregir.")
    end
  end

  handle_asynchronously :fix_punch, run_at: -> { 16.hours.from_now }

end
