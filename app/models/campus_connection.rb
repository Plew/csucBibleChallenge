class CampusConnection < ApplicationRecord
  belongs_to :user
  belongs_to :challenge, optional: true

  validates :campus_name, presence: true
  validates :hub_url, presence: true, uniqueness: { case_sensitive: false }
  validates :sso_secret, presence: true

  before_validation :normalize_hub_url

  private

  def normalize_hub_url
    return if hub_url.blank?
    # Strip trailing slash and whitespace for consistent matching
    self.hub_url = hub_url.strip.sub(%r{/+\z}, "")
  end
end
