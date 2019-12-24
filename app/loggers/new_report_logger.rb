# frozen_string_literal: true

class NewReportLogger < LoggerBase
  def self.log(report)
    reportable = report.reportable

    s = +"[REPORT: New] #{Booru::CONFIG.settings[:public_url_root]}/admin/reports/#{report.id}"
    s += " - Reporter: #{report.author(true)}"
    s += " - Reason: #{sanitize_newlines(report.reason)[0..100]}\n"

    if reportable.class < UserAttributable
      s += '[REPORT: User]'
      s += " - User: #{reportable.user ? reportable.user.name : reportable.author}"
      s += " - IP: #{reportable.ip}"
      s += " - FP: #{reportable.fingerprint&.slice(0..6)}"
    end

    modfeed_send(s)
  end
end
