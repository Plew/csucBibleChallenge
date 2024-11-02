class GroupsController < ApplicationController
  before_action :set_group, except: [:index, :new, :create, :create_or_join]

  def index
    @groups = current_user.groups

    if @groups.any?
      redirect_to @groups.first
    else
      render :create_or_join
    end
  end

  def show
    @pie_chart_data = PieDataFromGroupDay.new(@group, browser_date).pie_chart_data
    @next_group_id = CircularIntegerCollection.new(current_user.groups.pluck(:id), @group.id).next
    @previous_group_id = CircularIntegerCollection.new(current_user.groups.pluck(:id), @group.id).previous
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.creator = current_user
    @group.users << current_user
    if @group.save
      redirect_to @group
    else
      render :new
    end
  end

  # get for this
  def create_or_join
  end

  #get for this
  def group_key
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: 'Group was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_url, notice: 'Group was successfully destroyed.'
  end

  private

  def set_group
    @group = current_user.groups.find(params[:id])
  end

  def group_params
    params.permit(:name) # Add other permitted attributes as needed
  end
end