# frozen_string_literal: true

require 'faker'
FactoryBot.define do
  factory :offer do
    request_id { 1 }
    user_id { 1 }
    comment { 'MyString' }
    mobile { 'MyString' }
    email { Faker::Internet.email }
    roster_id { 1 }
  end
end
