class Scheduler::HomeController < Scheduler::BaseController
  helper Scheduler::FlexSchedulesHelper

  def root

  end

  def on_call

  end

  private
  helper_method :shifts_available_for_month
  def shifts_available_for_month(month)
    @shifts ||= Scheduler::Shift.joins{shift_group.outer}.includes{shift_group}.where{shift_group.chapter_id == my{current_person.chapter_id}}.can_be_taken_by(current_person)

    Scheduler::Shift.count_shifts_available_for_month(@shifts, month)
  end

  def current_time
    current_person.chapter.time_zone.now
  end

  expose(:upcoming_shifts) {
    [ Scheduler::ShiftAssignment.where(person_id: current_person).for_active_groups(Scheduler::ShiftGroup.current_groups_for_chapter(current_person.chapter, current_time)).to_a,
      Scheduler::ShiftAssignment.where(person_id: current_person).starts_after(current_time).includes(:shift => :shift_group).order{[date, shift.shift_group.start_offset]}.limit(3).to_a
    ].flatten.first(3)
  }

  #def current_person
  #  @_current_person ||= (params[:person_id] ? Roster::Person.find( params[:person_id]) : current_user)
  #end
  alias_method :current_person, :current_user

  expose :available_swaps do
    Scheduler::ShiftAssignment.available_for_swap(current_chapter)
      .order{[date, shift.shift_group.start_offset]}
      .select{|shift| shift.shift.can_be_taken_by? current_person}
  end

  helper_method :responses
  def responses
    @_responses ||= Incidents::ResponderAssignment.where(person_id: current_person).joins{incident}.includes{incident}.order('incidents_incidents.date desc').first(5)
  end

  helper_method :days_of_week, :shift_times, :current_person
    def days_of_week
      %w(sunday monday tuesday wednesday thursday friday saturday)
    end

    def shift_times
      %w(day night)
    end
end
