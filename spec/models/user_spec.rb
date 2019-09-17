require "rails_helper"
RSpec.describe User, :type => :model do

	before(:all) do
    @user = FactoryBot.create(:user)
  end

    context '#Atributes' do
	    it "is valid with valid attributes" do
	      expect(@user).to be_valid
	    end
	  end

  describe User, 'association' do
  it { should have_many(:awards) }
  it { should have_many(:requests) }
  it { should have_many(:offers) }
  it { should have_one(:patrol_member) }
  it { should have_one(:patrol).through(:patrol_member) }
  it { should have_many(:rosters).through(:patrol) }
  it { should have_many(:proficiency_signups) }
  it { should have_many(:proficiencies).through(:proficiency_signups) }
  it { should have_many(:swaps) }
  it { should have_many(:notices) }
  it { should have_many(:notice_acknowledgements) }
	end

 it "returns a user's full name as a string" do
   user = User.new(
     first_name: "John",
     last_name:  "Doe",
  )
  expect(user.name).to eq "John Doe"
 end

describe User do
  let(:club) { double(name: "organisation") }
    it "find club by name" do
      expect(Club).to receive(:find_by_name).and_return(club)
      expect(Club.find_by_name("organisation")).to eq club 
    end
end

end