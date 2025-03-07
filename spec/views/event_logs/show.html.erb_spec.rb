# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'event_logs/show', type: :view do
  before do
    @event_log = assign(:event_log, create(:event_log))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Subject/)
    expect(rendered).to match(/Desc/)
  end
end
