# frozen_string_literal: true

class Evaluation
  TYPES = [
    SIREN = "SIREN",
    VAT = "VAT"
  ].freeze

  STATES = [
    UNCONFIRMED = "unconfirmed",
    FAVORABLE = "favorable",
    UNFAVORABLE = "unfavorable"
  ].freeze

  REASONS = [
    COMPANY_OPENED = "company_opened",
    COMPANY_CLOSED = "company_closed",
    UNABLE_TO_REACH_API = "unable_to_reach_api",
    ONGOING_DATABASE_UPDATE = "ongoing_database_update"
  ].freeze

  SCORE_DECREASE_AMOUNT_PER_REASON_FOR_TYPE = {
    SIREN: {
      favorable: 1,
      gte_50_unconfirmed_unable_to_reach_api: 5,
      lt_50_unconfirmed_unable_to_reach_api: 1
    },
    VAT: {
      favorable: 1,
      gte_50_unconfirmed_unable_to_reach_api: 1,
      lt_50_unconfirmed_unable_to_reach_api: 3
    }
  }.freeze

  attr_accessor :type, :value, :score, :state, :reason

  def initialize(type:, value:, score:, state:, reason:)
    @type = type
    @value = value
    @score = score
    @state = state
    @reason = reason
  end

  def to_s
    "#{@type}, #{@value}, #{@score}, #{@state}, #{@reason}"
  end

  def unconfirmed?
    state == UNCONFIRMED
  end

  def favorable?
    state == FAVORABLE
  end

  def unable_to_reach_api?
    reason == UNABLE_TO_REACH_API
  end

  def ongoing_database_update?
    reason == ONGOING_DATABASE_UPDATE
  end

  def unconfirmed_ongoing_database_update?
    unconfirmed? && ongoing_database_update?
  end

  def unconfirmed_unable_to_reach_api?
    unconfirmed? && unable_to_reach_api?
  end

  def decrease_score(reason)
    return unless reason
    return unless SCORE_DECREASE_AMOUNT_PER_REASON_FOR_TYPE.keys.include?(type.to_sym)

    lower_score_by(SCORE_DECREASE_AMOUNT_PER_REASON_FOR_TYPE[type.to_sym][reason.to_sym] || 0)
  end

  private

  def lower_score_by(amount)
    amount = score if amount > score

    self.score = score - amount
  end
end
