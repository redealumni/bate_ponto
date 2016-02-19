class ReportsController < ApplicationController

  include DatetimeHelper

  before_filter :require_admin

  # GET /reports/index
  def index

  end

  # GET /reports/simple
  def simple
    partial = reports_params[:partial] == "true"
    date = partial ? Date.today : Date.today.prev_month
    date_range = get_weeks_of_month(date)

    result = CSV.generate do |csv|
      csv << ["Nome", "Meta de Horas Mensal", "Horas Trabalhadas", "Saldo de Horas"]
      User.visible.find_each do |u|
        summary = Summary.summary_for u, date_range, date, partial
        monthly_goal = summary.weeks.sum(&:weekly_goal).to_i
        worked_hours = summary.weeks.sum(&:hours).to_i
        csv << [u.name, monthly_goal, worked_hours, worked_hours - monthly_goal]
      end
    end

    send_data result, 
      filename: "relatorio_simples_#{I18n.l(Date.today, format: :filename)}.csv",
      type: :csv
  end

  # GET /reports/absences
  def absences
    date = reports_params[:partial] == "true" ? Date.today : Date.today.prev_month

    @absences = Summary.absences_for date
    @partial = reports_params[:partial] == "true"
  end

  # GET /reports/detailed
  def detailed
    partial = reports_params[:partial] == "true"
    date = partial ? Date.today : Date.today.prev_month

    temp_file = Tempfile.new("reports-#{request.uuid}")
    date_range = get_weeks_of_month(date)

    begin
      file_name = "relatorios_#{I18n.l(Date.today, format: :filename)}.zip"
      @format = :pdf

      Zip::OutputStream.open temp_file.path do |z|
        User.visible.find_each do |u|
          @summary = Summary.summary_for u, date_range, date, partial

          pdf_string = render_to_string formats: [:html],
            template: "users/report.html.erb",
            layout: "report_pdf"

          pdf_data = WickedPdf.new.pdf_from_string(pdf_string)

          z.put_next_entry "relatorio_#{@summary.user.name}.pdf"
          z.write pdf_data
        end
      end
      send_file temp_file.path, type: 'application/zip', filename: file_name
    ensure
      temp_file.close
    end
  end

  private
    # Safe parameters for admin reports
    def reports_params
      params.permit(:partial)
    end

end
