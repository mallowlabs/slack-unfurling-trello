# frozen_string_literal: true

require 'trello'

class TrelloClient
  CARD_URL_PATTERN = /\Ahttps:\/\/trello\.com\/c\/(\w+)(\/.*)?\z/.freeze

  def initialize
    Trello.configure do |config|
      config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
      config.member_token = ENV['TRELLO_MEMBER_TOKEN']
    end
  end

  def enabled?
    ENV['TRELLO_DEVELOPER_PUBLIC_KEY'] && ENV['TRELLO_MEMBER_TOKEN']
  end

  def target?(url)
    url =~ CARD_URL_PATTERN
  end

  def get(url)
    return nil unless url =~ CARD_URL_PATTERN

    begin
      card = Trello::Card.find($1)

      info = {
        title: card.name,
        title_link: card.url,
        text: card.desc,
        color: '#0079BF'
      }

      return info
    rescue Trello::Error => ex
      nil
    end
  end

end

