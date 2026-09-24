# CSV quoting handles separators, but does not prevent spreadsheet formula execution.
module SpreadsheetCsv
  def self.safe_text(value)
    text = value.to_s
    text.match?(/\A[[:space:]]*[=+@-]/) || text.start_with?("\t", "\r", "\n") ? "'#{text}" : text
  end
end
