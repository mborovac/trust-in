# frozen_string_literal: true

require File.join(File.dirname(__FILE__), "trustin")
require File.join(File.dirname(__FILE__), "evaluation")
require 'faker'

RSpec.describe TrustIn do
  describe "#update_score" do
    subject { described_class.new(evaluations).update_score }
    let(:evaluations) { [Evaluation.new(type: type, value: value, score: score, state: state, reason: reason)] }

    context "when the evaluation type is 'SIREN'" do
      let(:type) { Evaluation::SIREN }
      let(:value) { "123456789" }

      context "<state> is 'unconfirmed'" do
        let(:state) { Evaluation::UNCONFIRMED }

        context "<reason> is 'unable_to_reach_api'" do
          let(:reason) { Evaluation::UNABLE_TO_REACH_API }

          context "and <score> is greater than 50" do
            let(:score) { Faker::Number.between(from: 51, to: 100) }

            it "decreases the <score> by 5" do
              expect { subject }.to change { evaluations.first.score }.by(-5)
            end
          end

          context "and <score> is 50" do
            let(:score) { 50 }

            it "decreases the <score> by 5" do
              expect { subject }.to change { evaluations.first.score }.by(-5)
            end
          end

          context "and <score> is lower than 50 but greater than 0" do
            let(:score) { Faker::Number.between(from: 1, to: 49) }

            it "decreases the <score> by 1" do
              expect { subject }.to change { evaluations.first.score }.by(-1)
            end
          end

          context "and <score> is 0" do
            let(:score) { 0 }

            context "and new evaluation returns 'Actif' company state" do
              let(:value) { "832940670" }

              it "updates evaluation to favorable <state>, 'company_opened' <reason> and refreshes <score> to 100" do
                expect { subject }.to change { evaluations.first.state }.to(Evaluation::FAVORABLE)
                                  .and change { evaluations.first.reason }.to(Evaluation::COMPANY_OPENED)
                                  .and change { evaluations.first.score }.to(100)
              end
            end

            context "and new evaluation DOES NOT return 'Actif' company state" do
              let(:value) { "320878499" }

              it "updates evaluation to unfavorable <state>, 'company_closed' <reason> and refreshes <score> to 100" do
                expect { subject }.to change { evaluations.first.state }.to(Evaluation::UNFAVORABLE)
                                  .and change { evaluations.first.reason }.to(Evaluation::COMPANY_CLOSED)
                                  .and change { evaluations.first.score }.to(100)
              end
            end
          end
        end

        context "<reason> is 'ongoing_database_update'" do
          let(:reason) { Evaluation::ONGOING_DATABASE_UPDATE }

          [0, Faker::Number.between(from: 1, to: 49), 50, Faker::Number.between(from: 50, to: 99)].each do |curr_score|
            context "regardless of <score> value" do
              let(:score) { curr_score }

              context "and new evaluation returns 'Actif' company state" do
                let(:value) { "832940670" }

                it "updates evaluation to favorable <state>, 'company_opened' <reason> and refreshes <score> to 100" do
                  expect { subject }.to change { evaluations.first.state }.to(Evaluation::FAVORABLE)
                                    .and change { evaluations.first.reason }.to(Evaluation::COMPANY_OPENED)
                                    .and change { evaluations.first.score }.to(100)
                end
              end

              context "and new evaluation DOES NOT return 'Actif' company state" do
                let(:value) { "320878499" }

                it "updates evaluation to unfavorable <state>, 'company_closed' <reason> and refreshes <score> to 100" do
                  expect { subject }.to change { evaluations.first.state }.to(Evaluation::UNFAVORABLE)
                                    .and change { evaluations.first.reason }.to(Evaluation::COMPANY_CLOSED)
                                    .and change { evaluations.first.score }.to(100)
                end
              end
            end
          end
        end
      end

      # assuming favorable <status> can only be paired with <reason> 'company_opened'
      context "<state> is 'favorable', <reason> is 'company_opened'" do
        let(:state) { Evaluation::FAVORABLE }
        let(:reason) { Evaluation::COMPANY_OPENED }

        context "<score> is greater than 0" do
          let(:score) { Faker::Number.between(from: 1, to: 100) }

          it "decreases the <score> by 1" do
            expect { subject }.to change { evaluations.first.score }.by(-1)
          end
        end

        context "<score> is 0" do
          let(:score) { 0 }

          context "and new evaluation returns 'Actif' company state" do
            let(:value) { "832940670" }

            it "updates evaluation to favorable <state>, 'company_opened' <reason> and refreshes <score> to 100" do
              expect { subject }.to change { evaluations.first.score }.to(100)
            end
          end

          context "and new evaluation DOES NOT return 'Actif' company state" do
            let(:value) { "320878499" }

            it "updates evaluation to unfavorable <state>, 'company_closed' <reason> and refreshes <score> to 100" do
              expect { subject }.to change { evaluations.first.state }.to(Evaluation::UNFAVORABLE)
                                .and change { evaluations.first.reason }.to(Evaluation::COMPANY_CLOSED)
                                .and change { evaluations.first.score }.to(100)
            end
          end
        end
      end

      # assuming unfavorable <status> can only be paired with <reason> 'company_closed'
      context "<state> is 'unfavorable', <reason> is 'company_closed'" do
        let(:state) { Evaluation::UNFAVORABLE }
        let(:reason) { Evaluation::COMPANY_CLOSED }

        [Faker::Number.between(from: 1, to: 49), 50, Faker::Number.between(from: 50, to: 100)].each do |current_score|
          context "and <score> is greater than 0" do
            let(:score) { current_score }

            it "does not decrease its <score>" do
              expect { subject }.not_to change { evaluations.first.score }
            end
          end
        end

        context "and <score> is 0" do
          let(:score) { 0 }

          it "does not call the API" do
            expect(Net::HTTP).not_to receive(:get)
            expect(OpendatasoftEvaluationAccessor).not_to receive(:fetch_evaluation_data)
          end
        end
      end
    end

    context "when the evaluation type is 'VAT'" do
      let(:type) { Evaluation::VAT }
      let(:value) { %w(IE6388047V, LU26375245, GB727255821).sample }

      context "<state> is 'unconfirmed'" do
        let(:state) { Evaluation::UNCONFIRMED }

        context "<reason> is 'unable_to_reach_api'" do
          let(:reason) { Evaluation::UNABLE_TO_REACH_API }

          context "and <score> is greater than 50" do
            let(:score) { Faker::Number.between(from: 51, to: 100) }

            it "decreases the <score> by 1" do
              expect { subject }.to change { evaluations.first.score }.by(-1)
            end
          end

          context "and <score> is 50" do
            let(:score) { 50 }

            it "decreases the <score> by 1" do
              expect { subject }.to change { evaluations.first.score }.by(-1)
            end
          end

          context "and <score> is lower than 50 but greater than 3" do
            let(:score) { Faker::Number.between(from: 3, to: 49) }

            it "decreases the <score> by 3" do
              expect { subject }.to change { evaluations.first.score }.by(-3)
            end
          end

          context "and <score> is lower than 3 but greater than 0" do
            let(:score) { [1, 2].sample }

            it "sets the <score> to 0" do
              expect { subject }.to change { evaluations.first.score }.to(0)
            end
          end

          context "and <score> is 0" do
            let(:score) { 0 }
            let(:eval) {
              [
                { state: "favorable", reason: "company_opened" },
                { state: "unfavorable", reason: "company_closed" },
                # { state: "unconfirmed", reason: "unable_to_reach_api" },
                # { state: "unconfirmed", reason: "ongoing_database_update" }
              ].sample
            }

            it "updates evaluation according to the returned evaluation and refreshes <score> to 100" do
              expect(VatEvaluationAccessor).to receive(:fetch_evaluation_data).with(evaluations.first).and_return(eval)
              expect { subject }.to change { evaluations.first.state }.to(eval[:state])
                                .and change { evaluations.first.reason }.to(eval[:reason])
                                .and change { evaluations.first.score }.to(100)
            end
          end
        end

        context "<reason> is 'ongoing_database_update'" do
          let(:reason) { Evaluation::ONGOING_DATABASE_UPDATE }

          [0, Faker::Number.between(from: 1, to: 49), 50, Faker::Number.between(from: 50, to: 99)].each do |current_score|
            context "regardless of <score> value" do
              let(:score) { current_score }
              let(:eval) {
                [
                  { state: "favorable", reason: "company_opened" },
                  { state: "unfavorable", reason: "company_closed" },
                  # { state: "unconfirmed", reason: "unable_to_reach_api" },
                  # { state: "unconfirmed", reason: "ongoing_database_update" }
                ].sample
              }

              it "updates evaluation according to the returned evaluation and refreshes <score> to 100" do
                expect(VatEvaluationAccessor).to receive(:fetch_evaluation_data).with(evaluations.first).and_return(eval)
                expect { subject }.to change { evaluations.first.state }.to(eval[:state])
                                  .and change { evaluations.first.reason }.to(eval[:reason])
                                  .and change { evaluations.first.score }.to(100)
              end
            end
          end
        end
      end

      # assuming favorable <status> can only be paired with <reason> 'company_opened'
      context "<state> is 'favorable', <reason> is 'company_opened'" do
        let(:state) { Evaluation::FAVORABLE }
        let(:reason) { Evaluation::COMPANY_OPENED }

        context "<score> is greater than 0" do
          let(:score) { Faker::Number.between(from: 1, to: 100) }

          it "decreases the <score> by 1" do
            expect { subject }.to change { evaluations.first.score }.by(-1)
          end
        end

        context "<score> is 0" do
          let(:score) { 0 }
          let(:eval) {
            [
              # { state: "favorable", reason: "company_opened" },
              { state: "unfavorable", reason: "company_closed" },
              { state: "unconfirmed", reason: "unable_to_reach_api" },
              { state: "unconfirmed", reason: "ongoing_database_update" }
            ].sample
          }

          it "updates evaluation according to the returned evaluation and refreshes <score> to 100" do
            expect(VatEvaluationAccessor).to receive(:fetch_evaluation_data).with(evaluations.first).and_return(eval)
            expect { subject }.to change { evaluations.first.state }.to(eval[:state])
                              .and change { evaluations.first.reason }.to(eval[:reason])
                              .and change { evaluations.first.score }.to(100)
          end
        end
      end

      # assuming unfavorable <status> can only be paired with <reason> 'company_closed'
      context "<state> is 'unfavorable', <reason> is 'company_closed'" do
        let(:state) { Evaluation::UNFAVORABLE }
        let(:reason) { Evaluation::COMPANY_CLOSED }

        [Faker::Number.between(from: 1, to: 49), 50, Faker::Number.between(from: 50, to: 100)].each do |current_score|
          context "and <score> is greater than 0" do
            let(:score) { current_score }

            it "does not decrease its <score>" do
              expect { subject }.not_to change { evaluations.first.score }
            end
          end
        end

        context "and <score> is 0" do
          let(:score) { 0 }

          it "does not call the API" do
            expect(Net::HTTP).not_to receive(:get)
            expect(VatEvaluationAccessor).not_to receive(:fetch_evaluation_data)
          end
        end
      end
    end
  end
end
