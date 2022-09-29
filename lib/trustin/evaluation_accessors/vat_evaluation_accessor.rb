# frozen_string_literal: true

class VatEvaluationAccessor
  def self.fetch_evaluation_data(_evaluation)
    [
      { state: "favorable", reason: "company_opened" },
      { state: "unfavorable", reason: "company_closed" },
      { state: "unconfirmed", reason: "unable_to_reach_api" },
      { state: "unconfirmed", reason: "ongoing_database_update" }
    ].sample
  end
end
