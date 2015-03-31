class ReportUtil
  include RenderAnywhere
  include DatetimeHelper

  def reports(ids, month_days, folder = "#{Dir.home}/reports")
    @format = :pdf
    users = User.find(ids)

    month_days.each do |month_day|
      date_range = get_weeks_of_month(month_day)
      range_string = [date_range.first.begin, date_range.last.end].map do |date|
        I18n.l(date.to_date, format: :filename)
      end.join('_a_')

      file_name = "#{folder}/relatorios_#{range_string}.zip"

      Zip::File.open(file_name, Zip::File::CREATE) do |z|
        users.each do |u|
          @summary = Summary.summary_for u, date_range, month_day, true

          pdf_string = render_to_string formats: [:html],
            template: "users/report.html.erb",
            layout: "report_pdf"

          pdf_data = WickedPdf.new.pdf_from_string(pdf_string)

          z.get_output_stream("relatorio_#{@summary.user.name}.pdf") { |os| os.write(pdf_data) }
        end
      end
    end
    
  end
end