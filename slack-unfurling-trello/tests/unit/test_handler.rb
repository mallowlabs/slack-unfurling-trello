# frozen_string_literal: true

require 'minitest/autorun'
require 'webmock/minitest'

require_relative '../../app.rb'

class AppTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!

    @original_developer_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
    @original_member_token = ENV['TRELLO_MEMBER_TOKEN']
    ENV['TRELLO_DEVELOPER_PUBLIC_KEY'] = 'dummy_key'
    ENV['TRELLO_MEMBER_TOKEN'] = 'dummy_token'
  end

  def teardown
    ENV['TRELLO_DEVELOPER_PUBLIC_KEY'] = @original_developer_key
    ENV['TRELLO_MEMBER_TOKEN'] = @original_member_token
  end

  def event(body)
    {
      'body' => body,
    }
  end

  def test_url_verification_404
    ENV['TRELLO_DEVELOPER_PUBLIC_KEY'] = nil
    ENV['TRELLO_MEMBER_TOKEN'] = nil

    e = event({
      type: 'url_verification'
    }.to_json)

    expected_result = { statusCode: 404, body: JSON.generate(ok: false) }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

  def test_url_verification_200
    e = event({
      type: 'url_verification',
      challenge: 'example'
    }.to_json)

    expected_result = { statusCode: 200, body: JSON.generate(challenge: 'example') }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

  def test_event_callback_board
    e = event({
      type: 'event_callback',
      event: {
        channel: 'channel_name',
        message_ts: '1234567890.123456',
        links: [
          { url: 'https://trello.com/b/123456' }
        ]
      }
    }.to_json)

    stub_request(:get, 'https://api.trello.com/1/boards/123456?key=dummy_key&token=dummy_token').
      to_return(status: 200, body: {
        id: '123456',
        name: "board_name",
        url: 'https://trello.com/b/123456',
        desc: 'board_description'
      }.to_json, headers: { }
    )

    stub_request(:post, 'https://slack.com/api/chat.unfurl').
      with(
        body: {
          channel: 'channel_name',
          ts: '1234567890.123456',
          unfurls: {
            'https://trello.com/b/123456': {
              title: 'board_name',
              title_link: 'https://trello.com/b/123456',
              text: 'board_description',
              color: '#0079BF'
            }
          }
        }.to_json
      ).to_return(status: 200, body: "", headers: {})

    expected_result = { statusCode: 200, body: JSON.generate(ok: true) }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

  def test_event_callback_card
    e = event({
      type: 'event_callback',
      event: {
        channel: 'channel_name',
        message_ts: '1234567890.123456',
        links: [
          { url: 'https://trello.com/c/123456' }
        ]
      }
    }.to_json)

    stub_request(:get, 'https://api.trello.com/1/cards/123456?key=dummy_key&token=dummy_token').
      to_return(status: 200, body: {
        id: '123456',
        name: "card_name",
        url: 'https://trello.com/c/123456',
        desc: 'card_description'
      }.to_json, headers: { }
    )

    stub_request(:post, 'https://slack.com/api/chat.unfurl').
      with(
        body: {
          channel: 'channel_name',
          ts: '1234567890.123456',
          unfurls: {
            'https://trello.com/c/123456': {
              title: 'card_name',
              title_link: 'https://trello.com/c/123456',
              text: 'card_description',
              color: '#0079BF'
            }
          }
        }.to_json
      ).to_return(status: 200, body: "", headers: {})

    expected_result = { statusCode: 200, body: JSON.generate(ok: true) }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

  def test_event_callback_card_comment
    e = event({
      type: 'event_callback',
      event: {
        channel: 'channel_name',
        message_ts: '1234567890.123456',
        links: [
          { url: 'https://trello.com/c/123456/#comment-7890' }
        ]
      }
    }.to_json)

    stub_request(:get, 'https://api.trello.com/1/cards/123456?key=dummy_key&token=dummy_token').
      to_return(status: 200, body: {
        id: '123456',
        name: "card_name",
        url: 'https://trello.com/c/123456',
        desc: 'card_description'
      }.to_json, headers: { }
    )

    stub_request(:get, 'https://api.trello.com/1/cards/123456/actions?filter=commentCard&key=dummy_key&token=dummy_token').
      to_return(status: 200, body:
        [
          {
            id: '7890',
            data: {
              text: 'comment_text'
            }
          }
        ].to_json, headers: { }
    )

    stub_request(:post, 'https://slack.com/api/chat.unfurl').
      with(
        body: {
          channel: 'channel_name',
          ts: '1234567890.123456',
          unfurls: {
            'https://trello.com/c/123456/#comment-7890': {
              title: 'card_name',
              title_link: 'https://trello.com/c/123456#comment-7890',
              text: 'comment_text',
              color: '#0079BF'
            }
          }
        }.to_json
      ).to_return(status: 200, body: "", headers: {})

    expected_result = { statusCode: 200, body: JSON.generate(ok: true) }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end
end
