# frozen_string_literal: true

require 'trello'

class TrelloClient
  TRELLO_URL_PATTERN = /\Ahttps:\/\/trello\.com\/([cb])\/(\w+)(\/[^#]*)?(#comment-\w+)?\z/.freeze
  TRELLO_COLOR = '#0079BF'

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
    url =~ TRELLO_URL_PATTERN
  end

  def get(url)
    return nil unless url =~ TRELLO_URL_PATTERN

    begin
      case $1
      when 'c'
        card = Trello::Card.find($2)
        info = {
          title: card.name,
          title_link: card.url,
          text: card.desc,
          color: TRELLO_COLOR
        }
        if $4 # comment
          comment_id = $4.gsub(/#comment-/, '')
          comment = card.comments.detect { |c| c.id == comment_id }
          if comment
            info = {
              title: card.name,
              title_link: "#{card.url}#comment-#{comment_id}",
              text: comment.data[:text],
              color: TRELLO_COLOR
            }
          end
        end
      when 'b'
        board = Trello::Board.find($2)
        info = {
          title: board.name,
          title_link: board.url,
          text: board.description,
          color: TRELLO_COLOR
        }
      else
        info = nil
      end

      return info
    rescue Trello::Error
      nil
    end
  end

end

