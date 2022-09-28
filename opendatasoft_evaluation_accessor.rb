# frozen_string_literal: true

require "json"
require "net/http"

class OpendatasoftEvaluationAccessor
  def self.fetch_evaluation_data(evaluation)
    uri = URI("https://public.opendatasoft.com/api/records/1.0/search/?dataset=sirene_v3" \
              "&q=#{evaluation.value}&sort=datederniertraitementetablissement" \
              "&refine.etablissementsiege=oui")
    response = Net::HTTP.get(uri)
    parsed_response = JSON.parse(response)
    parsed_response["records"].first["fields"]["etatadministratifetablissement"]
  end
end
