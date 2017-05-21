class PeopleController < ApplicationController
  include Searchable
  before_action :authenticate_user!
  before_action :not_submitter!
  after_action :restrict_people

  # GET /people
  # GET /people.xml
  def index
    authorize! :administrate, Person
    @people = search Person.involved_in(@conference)

    respond_to do |format|
      format.html { @people = @people.paginate page: page_param }
      format.xml  { render xml: @people }
      format.json { render json: @people }
    end
  end

  def speakers
    authorize! :administrate, Person

    respond_to do |format|
      format.html do
        result = search Person.involved_in(@conference)
        @people = result.paginate page: page_param
      end
      format.text do
        @people = Person.speaking_at(@conference).accessible_by(current_ability)
        render text: @people.map(&:email).join("\n")
      end
    end
  end

  def all
    authorize! :administrate, Person
    result = search Person
    @people = result.paginate page: page_param

    respond_to do |format|
      format.html
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @person = Person.find(params[:id])
    authorize! :read, @person
    @view_model = PersonViewModel.new(@person, @conference)
    @view_model.redact_events! unless can?(:crud, Event)

    respond_to do |format|
      format.html
      format.xml { render xml: @person }
      format.json { render json: @person }
    end
  end

  def feedbacks
    @person = Person.find(params[:id])
    authorize! :access, :event_feedback
    @current_events = @person.events_as_presenter_in(@conference)
    @other_events = @person.events_as_presenter_not_in(@conference)
  end

  def attend
    @person = Person.find(params[:id])
    @person.set_role_state(@conference, 'attending')
    redirect_to action: :show
  end

  # GET /people/new
  def new
    @person = Person.new
    authorize! :manage, @person

    respond_to do |format|
      format.html
    end
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
    if @person.nil?
      flash[:alert] = 'Not a valid person'
      return redirect_to action: :index
    end
    authorize! :manage, @person
  end

  # POST /people
  def create
    @person = Person.new(person_params)
    authorize! :manage, @person

    respond_to do |format|
      if @person.save
        format.html { redirect_to(@person, notice: 'Person was successfully created.') }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PUT /people/1
  def update
    @person = Person.find(params[:id])
    authorize! :manage, @person

    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to(@person, notice: 'Person was successfully updated.') }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # DELETE /people/1
  def destroy
    @person = Person.find(params[:id])
    authorize! :manage, @person
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(people_url) }
    end
  end

  private

  def restrict_people
    @people = @people.accessible_by(current_ability) unless @people.nil?
  end

  def search(people)
    @search = perform_search(people, params,
      %i(first_name_cont last_name_cont public_name_cont email_cont
      abstract_cont description_cont user_email_cont))
    @search.result(distinct: true)
  end

  def person_params
    params.require(:person).permit(
      :first_name, :last_name, :public_name, :email, :email_public, :gender, :avatar, :abstract, :description, :include_in_mailings, :note,
      im_accounts_attributes: %i(id im_type im_address _destroy),
      languages_attributes: %i(id code _destroy),
      links_attributes: %i(id title url _destroy),
      phone_numbers_attributes: %i(id phone_type phone_number _destroy),
      ticket_attributes: %i(id remote_ticket_id)
    )
  end
end
