# frozen_string_literal: true

class ReportLogger < LoggerBase
  def self.log(report, status)
    s = +"[REPORT: #{status}] #{Booru::CONFIG.settings[:public_url_root]}/admin/reports/#{report.id}"
    s += " - Reporter: #{report.author(true)}"
    s += " - #{status}"
    s += " by #{report.admin.name}" if report.admin

    modfeed_send(s)
  end
end
