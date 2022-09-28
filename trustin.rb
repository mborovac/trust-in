# frozen_string_literal: true

require_relative "evaluation"
require_relative "opendatasoft_evaluation_accessor"
require_relative "vat_evaluation_accessor"

class TrustIn
  def initialize(evaluations)
    @evaluations = evaluations
  end

  def update_score
    @evaluations.each do |evaluation|
      next unless Evaluation::TYPES.include?(evaluation.type)

      if evaluation.score.positive?
        evaluation.unconfirmed_ongoing_database_update? ?
          update_evaluation(evaluation) :
          evaluation.decrease_score(get_score_decrease_reason(evaluation))
      elsif evaluation.favorable? || evaluation.unconfirmed?
        update_evaluation(evaluation)
      end
    end
  end

  private

  def get_score_decrease_reason(evaluation)
    return :favorable if evaluation.favorable?

    if evaluation.unconfirmed_unable_to_reach_api?
      return evaluation.score >= 50 ? :gte_50_unconfirmed_unable_to_reach_api : :lt_50_unconfirmed_unable_to_reach_api
    end

    nil
  end

  def update_evaluation(evaluation)
    send("update_#{evaluation.type.downcase}_evaluation", evaluation)
  end

  def update_siren_evaluation(evaluation)
    company_state = OpendatasoftEvaluationAccessor.fetch_evaluation_data(evaluation)
    if company_state == "Actif"
      evaluation.state = Evaluation::FAVORABLE
      evaluation.reason = Evaluation::COMPANY_OPENED
    else
      evaluation.state = Evaluation::UNFAVORABLE
      evaluation.reason = Evaluation::COMPANY_CLOSED
    end

    evaluation.score = 100
  end

  def update_vat_evaluation(evaluation)
    company_state = VatEvaluationAccessor.fetch_evaluation_data(evaluation)
    evaluation.state = company_state[:state]
    evaluation.reason = company_state[:reason]
    evaluation.score = 100
  end
end
