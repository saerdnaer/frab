class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :not_submitter!

  def create
    if not @conference.ticket_server_enabled? or @conference.ticket_server.nil?
      return redirect_to edit_conference_path(conference_acronym: @conference.acronym), alert: 'No ticket server configured'
    end

    server = @conference.ticket_server

    if params.key?(:event_id)
      @event = Event.find(params[:event_id])
      authorize! :crud, @event

      begin
        title = t(:your_submission, locale: @event.language) + ' ' + @event.title.truncate(30)
        remote_id = server.create_remote_ticket(title: title,
                                                requestors: server.create_ticket_requestors(@event.speakers),
                                                owner_email: current_user.email,
                                                frab_url: event_url(@event),
                                                test_only: params[:test_only])
      rescue => ex
        return redirect_to event_path(id: params[:event_id], method: :get), alert: "Failed to create ticket: #{ex.message}"
      end

      if remote_id.nil?
        return redirect_to event_path(id: params[:event_id], method: :get), alert: 'Failed to receive remote id'
      end

      @event.ticket = Ticket.new if @event.ticket.nil?
      @event.ticket.remote_ticket_id = remote_id
      @event.save
      redirect_to event_path(id: params[:event_id], method: :get)
    end

    if params.key?(:person_id)
      @person = Person.find(params[:person_id])
      authorize! :crud, @person

      begin
        remote_id = server.create_remote_ticket(title: @person.full_name,
                                                requestors: @person.email,
                                                owner_email: current_user.email,
                                                frab_url: person_url(@person),
                                                test_only: params[:test_only])
      rescue => ex
        return redirect_to person_path(id: params[:person_id], method: :get), alert: "Failed to create ticket: #{ex.message}"
      end

      if remote_id.nil?
        return redirect_to person_path(id: params[:person_id], method: :get), alert: 'Failed to receive remote id'
      end

      @person.ticket = Ticket.new if @person.ticket.nil?
      @person.ticket.remote_ticket_id = remote_id
      @person.save
      redirect_to person_path(id: params[:person_id], method: :get)
    end
  end
end
