# frozen_string_literal: true

require_relative 'lib/slack_unfurling'
require_relative 'lib/trello_client'

def lambda_handler(event:, context:)
  SlackUnfurling.new(TrelloClient.new).call(event)
end
