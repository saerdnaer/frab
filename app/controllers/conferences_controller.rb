class ConferencesController < ApplicationController
  include Searchable
  # these methods don't need a conference
  skip_before_action :load_conference, only: [:new, :index, :create]

  before_action :authenticate_user!
  before_action :not_submitter!
  load_and_authorize_resource

  # GET /conferences
  def index
    result = search

    respond_to do |format|
      format.html { @conferences = result.paginate page: page_param }
      format.json { render json: result }
    end
  end

  # GET /conferences/1
  def show
    @conference = Conference.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @conference }
    end
  end

  # GET /conferences/new
  def new
    params.delete(:conference_acronym)
    @conference = Conference.new
    @possible_parents = Conference.where(parent: nil)
    @first = true if Conference.count == 0

    respond_to do |format|
      format.html
    end
  end

  # GET /conferences/1/edit
  def edit
  end

  def edit_notifications
    respond_to do |format|
      format.html
    end
  end

  def send_notification
    SendBulkTicketJob.new.async.perform @conference, params[:notification]
    redirect_to edit_notifications_conference_path, notice: 'Bulk notifications for events in ' + params[:notification] + ' enqueued.'
  end

  # POST /conferences
  def create
    @conference = Conference.new(conference_params)

    if @conference.sub_conference? and not can? :administate, @conference.parent
      @conference.parent = nil
    end

    respond_to do |format|
      if @conference.save
        format.html { redirect_to(conference_home_path(conference_acronym: @conference.acronym), notice: 'Conference was successfully created.') }
      else
        @possible_parents = Conference.where(parent: nil)
        flash[:errors] = @conference.errors.full_messages.join
        format.html { render action: 'new' }
      end
    end
  end

  # PUT /conferences/1
  def update
    respond_to do |format|
      if @conference.update_attributes(existing_conference_params)
        format.html { redirect_to(edit_conference_path(conference_acronym: @conference.acronym), notice: 'Conference was successfully updated.') }
      else
        # redirect to the right nested form page
        flash[:errors] = @conference.errors.full_messages.join
        format.html { render action: get_previous_nested_form(existing_conference_params) }
      end
    end
  end

  def default_notifications
    locale = params[:code]
    @notification = Notification.new(locale: locale)
    @notification.default_text = locale
  end

  # DELETE /conferences/1
  def destroy
    @conference.destroy

    respond_to do |format|
      format.html { redirect_to(conferences_path) }
    end
  end

  private

  def get_previous_nested_form(parameters)
    parameters.keys.each { |name|
      attribs = name.index('_attributes')
      next if attribs.nil?
      next unless attribs.positive?
      test = name.gsub('_attributes', '')
      next unless %w(rooms days schedule notifications tracks ticket_server).include?(test)
      return "edit_#{test}"
    }
    'edit'
  end

  def search
    @search = perform_search(Conference, params, %i(title_cont acronym_cont))
    @search.result(distinct: true)
  end

  def allowed_params
    [
      :acronym, :bulk_notification_enabled, :color, :default_recording_license, :default_timeslots, :email,
      :event_state_visible, :expenses_enabled, :feedback_enabled, :max_timeslots, :program_export_base_url,
      :schedule_custom_css, :schedule_html_intro, :schedule_public, :schedule_version, :ticket_type,
      :title, :transport_needs_enabled,
      languages_attributes: %i(language_id code _destroy id),
      ticket_server_attributes: %i(url user password queue _destroy id),
      notifications_attributes: %i(id locale accept_subject accept_body reject_subject reject_body schedule_subject schedule_body _destroy)
    ]
  end

  def conference_params
    allowed = allowed_params

    allowed += if params[:conference][:parent_id].present?
                 [:parent_id]
               else
                 [
                   :timezone, :timeslot_duration,
                   days_attributes: %i(start_date end_date _destroy id)
                 ]
               end

    params.require(:conference).permit(allowed)
  end

  def existing_conference_params
    allowed = allowed_params

    allowed += [:parent_id] if @conference.new_record?

    if @conference.main_conference?
      allowed += [
        :timezone, :timeslot_duration,
        days_attributes: %i(start_date end_date _destroy id)
      ]
    end

    if @conference.main_conference? || can?(:adminstrate, @conference.parent)
      allowed += [
        rooms_attributes: %i(name size public rank _destroy id),
        tracks_attributes: %i(name color _destroy id)
      ]
    end

    params.require(:conference).permit(allowed)
  end
end
