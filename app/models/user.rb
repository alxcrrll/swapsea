# frozen_string_literal: true

class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable  :validatable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable

  after_create :assign_default_role

  belongs_to :club
  has_many :awards
  has_many :tokens
  has_many :requests
  has_many :offers
  has_one :patrol_member
  has_one :patrol, through: :patrol_member
  has_many :rosters, through: :patrol
  has_many :proficiency_signups
  has_many :proficiencies, through: :proficiency_signups
  has_many :outreach_patrol_sign_ups
  has_many :outreach_patrol, through: :outreach_patrol_sign_ups
  has_many :swaps
  has_many :notices
  has_many :notice_acknowledgements

  scope :with_club, ->(club_id) { where(club_id:) }

  include PgSearch::Model
  pg_search_scope :search, against: %i[first_name last_name],
                           using: { tsearch: { dictionary: 'english' } }

  def self.text_search(query)
    if query.present?
      search(query)
    else
      scoped
    end
  end

  def self.awards
    users = User.all
    users.each do |user|
      user.bronze = user.awards.where(award_name: 'Bronze Medallion').present?
      user.bbm = user.awards.where(award_name: 'Silver Medallion Beach Management').present?
      user.artc = user.awards.where({ award_name: 'Advanced Resuscitation Techniques Certificate' } || { award_name: 'Advanced Resuscitation Techniques [AID]' } || { award_name: 'Advanced Resuscitation Techniques Refresher' } || { award_name: 'Advanced Resuscitation Certificate' } || { award_name: 'Advanced Resuscitation Certificate Instructor' }).present?
      user.irbd = user.awards.where(award_name: 'Silver Medallion IRB Driver').present?
      user.irbc = user.awards.where(award_name: 'IRB Crew Certificate').present?
      user.src = user.awards.where({ award_name: 'Surf Rescue Certificate' } || { award_name: 'Surf Rescue Certificate (CPR Endorsed)' }).present?
      user.save
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def email_exists_on_multiple_users?
    User.where(email:).count > 1
  end

  def assign_default_role
    add_role(:member)
  end

  def default_position
    self[:default_position] || 'Member'
  end

  def has_position?(position)
    if patrol_member.present? && patrol_member.default_position.present?
      patrol_member.default_position.parameterize.underscore.to_sym == position
    else
      false
    end
  end

  def has_patrol?
    patrol.present?
  end

  def offers_available_for(request)
    offers = []

    rosters = custom_roster - request.user.custom_roster
    rosters.each do |roster|
      if !request.offer_already_exists?(roster,
                                        self) && (DateTime.now <= roster.start) && !request.roster.user_rostered_on(self)
        offers << roster
      end
    end

    offers
  end

  def custom_roster
    custom_roster = rosters.includes([:patrol]).where('start >= ?', Time.zone.now.to_s(:db)).distinct + additional_rosters
    subtracted_rosters.each do |roster|
      # Check first, they may have moved patrols mid-season
      custom_roster.delete_at(custom_roster.index(roster)) if custom_roster.index(roster)
    end
    custom_roster.sort_by(&:start)
  end

  def next_roster
    custom_roster.first
  end

  def additional_rosters
    swaps.select('roster_id, user_id').where(on_off_patrol: true).joins(:roster).where('start >= ?',
                                                                                       Time.zone.now.to_s(:db)).map(&:roster)
  end

  def subtracted_rosters
    swaps.select('roster_id, user_id').where(on_off_patrol: false).joins(:roster).where('start >= ?',
                                                                                        Time.zone.now.to_s(:db)).map(&:roster)
  end

  def has_multiple_emails?
    User.where(email:).count >= 2
  end

  def qualifications
    bronze = awards.where(award_name: 'Bronze Medallion').count
    bbm = awards.where(award_name: 'Silver Medallion Beach Management').count
    artc = awards.where({ award_name: 'Advanced Resuscitation Techniques Certificate' } || { award_name: 'Advanced Resuscitation Techniques [AID]' } || { award_name: 'Advanced Resuscitation Techniques Refresher' } || { award_name: 'Advanced Resuscitation Certificate' } || { award_name: 'Advanced Resuscitation Certificate Instructor' }).count
    irbd = awards.where(award_name: 'Silver Medallion IRB Driver').count
    irbc = awards.where(award_name: 'IRB Crew Certificate').count
    src = awards.where({ award_name: 'Surf Rescue Certificate' } || { award_name: 'Surf Rescue Certificate (CPR Endorsed)' }).count
    {
      bronze:,
      bbm:,
      artc:,
      irbd:,
      irbc:,
      src:
    }
  end

  def generate_ics
    self.ics = Digest::SHA256.hexdigest(('a'..'z').to_a.sample(10).join)
  end

  def self.upload(file)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(5)
    club = nil
    (6..spreadsheet.last_row).each do |i|
      row = [header, spreadsheet.row(i)].transpose.to_h

      # Look up club once per import file.
      club ||= Club.find_by!(name: row['Organisation Display Name'])

      user = find_or_initialize_by(id: row['Member ID'])
      user.club_id = club.id
      user.first_name = row['First Name']
      user.last_name = row['Last Name']
      user.preferred_name = row['Preferred Name']
      user.gender = row['Gender']
      user.dob = row['Date of Birth']
      user.mobile_phone = row['Mobile Phone'].split('\'')[1] if row['Mobile Phone'].present?
      user.email = row['Email Address 1']
      user.category = row['Membership Category']
      user.date_joined_organisation = row['Date Joined'] || DateTime.iso8601('1900-01-01')
      user.status = row['Status']
      user.season = row['Season']

      user.ics = Digest::SHA512.hexdigest(('a'..'z').to_a.sample(64).join) if user.ics.blank?

      user.save!
    end
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv' then Roo::CSV.new(file.path)
    when '.xls' then Roo::Excel.new(file.path)
    when '.xlsx' then Roo::Excelx.new(file.path)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.juniors
    all.where(patrol_member: nil).where.not(dob: nil).select { |u| (Date.today.year - u.dob.year) < 19 }
  end
end
