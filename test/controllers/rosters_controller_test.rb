# frozen_string_literal: true

require 'test_helper'

class RostersControllerTest < ActionController::TestCase
  before do
    @roster = rosters(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:rosters)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create roster' do
    assert_difference('Roster.count') do
      post :create,
           params: { roster: { finish: @roster.finish, key: @roster.key, organisation: @roster.organisation,
                               patrol: @roster.patrol, start: @roster.start } }
    end

    assert_redirected_to roster_path(assigns(:roster))
  end

  test 'should show roster' do
    get :show, params: { id: @roster }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @roster }
    assert_response :success
  end

  test 'should update roster' do
    patch :update,
          params: { id: @roster,
                    roster: { finish: @roster.finish, key: @roster.key, organisation: @roster.organisation, patrol: @roster.patrol,
                              start: @roster.start } }
    assert_redirected_to roster_path(assigns(:roster))
  end

  test 'should destroy roster' do
    assert_difference('Roster.count', -1) do
      delete :destroy, params: { id: @roster }
    end

    assert_redirected_to rosters_path
  end
end
