require_relative "evaluation"
require_relative "opendatasoft_evaluation_accessor"

class TrustIn
  def initialize(evaluations)
    @evaluations = evaluations
  end

  def update_score()
    @evaluations.each do |evaluation|
      next unless evaluation.type == Evaluation::SIREN

      if evaluation.score > 0
        evaluation.unconfirmed_ongoing_database_update? ?
          update_evaluation(evaluation) :
          evaluation.decrease_score(get_score_decrease_reason(evaluation))
      else
        update_evaluation(evaluation) if evaluation.favorable? || evaluation.unconfirmed?
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
end
