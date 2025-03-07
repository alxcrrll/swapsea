# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Offer, type: :model do
  before do
    @offer = create(:offer)
  end

  describe '#Atributes' do
    it 'is valid with valid attributes' do
      expect(@offer).to be_valid
    end

    it 'has default status pending' do
      expect(@offer).to have_attributes(status: 'pending')
    end
  end

  describe Offer, 'association' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:request) }
    it { is_expected.to belong_to(:roster) }
  end

  describe 'instance methods' do
    describe 'decline' do
      it 'status declined without remark' do
        @offer.decline(nil)
        expect(@offer.status).to eq('declined')
        expect(@offer.decline_remark).to be_nil
      end

      it 'status declined with remark' do
        remark = 'sorry mate'
        @offer.decline(remark)
        expect(@offer.status).to eq('declined')
        expect(@offer.decline_remark).to eq(remark)
      end
    end

    describe 'withdraw' do
      it 'from status pending' do
        expect(@offer.withdraw).to be_truthy
        expect(@offer.status).to eq('withdrawn')
      end

      it 'from status withdrawn' do
        @offer.withdraw
        expect(@offer.withdraw).to be_truthy
      end

      it 'from status unsuccessful' do
        @offer.unsuccessful
        expect(@offer.withdraw).to be_falsey
      end

      it 'from status cancelled' do
        @offer.cancel
        expect(@offer.withdraw).to be_falsey
      end
    end

    describe 'cancel' do
      it 'status cancelled' do
        expect(@offer.cancel).to be_truthy
        expect(@offer.status).to eq('cancelled')
      end
    end

    describe 'unsuccessful' do
      it 'status unsuccessful' do
        expect(@offer.unsuccessful).to be_truthy
        expect(@offer.status).to eq('unsuccessful')
      end
    end
  end
end
