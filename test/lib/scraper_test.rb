# frozen_string_literal: true

require 'test_helper'
require 'booru'

class ScraperTest < ActiveSupport::TestCase
  test 'should fetch direct image links' do
    direct_link = 'http://66.media.tumblr.com/fc3f8319a8a30d0f47f61ac78857a0ad/tumblr_o9y1ntPL2n1uaqvn6o1_500.png'

    VCR.use_cassette('scraper-direct-link', serialize_with: :compressed) do
      response = Booru::Scraper.scrape(direct_link)
      expected = Booru::ScraperResult.new(source_url: direct_link, images: response.images)
      assert_equal response, expected
      assert_equal response.images[0].url, direct_link
    end
  end

  test 'should fetch deviantart posts' do
    deviantart_link = 'https://www.deviantart.com/sugarlesspaints/art/Cewestia-and-Woona-776753159'
    direct_link = 'https://api-da.wixmp.com/_api/download/file?downloadToken=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsImV4cCI6MTU2MDY0ODAzNywiaWF0IjoxNTYwNjQ3NDI3LCJqdGkiOiI1ZDA1OTcwZGVmM2Y2Iiwib2JqIjpudWxsLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdLCJwYXlsb2FkIjp7InBhdGgiOiJcL2ZcLzMxYTAyZDYxLWVjYTgtNDZlZS1iNzdhLWMyNWQzYTU3YTg3MVwvZGN1Z2lrbi05OWZkZTgzYi04OTk1LTQxYTMtOWU5Ny1mZmIzZjNhYmZjM2EuanBnIiwiYXR0YWNobWVudCI6eyJmaWxlbmFtZSI6ImNld2VzdGlhX2FuZF93b29uYV9ieV9zdWdhcmxlc3NwYWludHNfZGN1Z2lrbi5qcGcifX19.8Z8q3xqWcHU6Lx1qw9DCjxAVHPKkM_795ijyIVr_E_8'

    VCR.use_cassette('scraper-deviantart-post', serialize_with: :compressed) do
      response = Booru::Scraper.scrape(deviantart_link)
      expected = Booru::ScraperResult.new(
        source_url:  deviantart_link,
        author_name: 'SugarlessPaints',
        description: "\u25CF PATREON \u25CF DeviantART \u25CF Newgrounds \u25CF Inkbunny \u25CF Pixiv \u25CF Twitter \u25CF Picarto \u25CF",
        images:      response.images
      )
      assert_equal response, expected
      assert_equal response.images[0].url, direct_link
    end
  end

  test 'should fall back on direct image link for mature content deviantart posts' do
    deviantart_link = 'https://www.deviantart.com/avante92/art/The-Great-and-Lustful-Trixie-answer-2-300965890'
    direct_link = 'https://api-da.wixmp.com/_api/download/file?downloadToken=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsImV4cCI6MTU2MDY0ODAzMiwiaWF0IjoxNTYwNjQ3NDIyLCJqdGkiOiI1ZDA1OTcwOGFhNWE1Iiwib2JqIjpudWxsLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdLCJwYXlsb2FkIjp7InBhdGgiOiJcL2ZcLzYxYWJmZDdlLTI0YzctNDljMy1hNDZhLWJjZjM3MmM5Y2ZlYlwvZDR6NnFybS1iOTBlMmZkZi0wZTkzLTQ5NjgtODVmOS1mNDBkYzg4ODRhNzEucG5nIiwiYXR0YWNobWVudCI6eyJmaWxlbmFtZSI6InRoZV9ncmVhdF9hbmRfbHVzdGZ1bF90cml4aWVfYW5zd2VyXzJfYnlfYXZhbnRlOTJfZDR6NnFybS5wbmcifX19.ibVv_-m_06JTOq4c6ELcQ7Ec_ReDAXTH_mXF0IrGPo4'

    VCR.use_cassette('scraper-mature-deviantart-net-link', serialize_with: :compressed) do
      response = Booru::Scraper.scrape(deviantart_link)
      expected = Booru::ScraperResult.new(
        source_url:  deviantart_link,
        author_name: 'avante92',
        description: "heres a pic answer i drew as a update to my Trixie tumblr,warning very NSFW,so i warn you now dont go if you cant handle it \n\noh heres the link :[link]",
        images:      response.images
      )
      assert_equal response, expected
      assert_equal response.images[0].url, direct_link
    end
  end

  test 'should fetch deviantart posts linked via fav.me' do
    fav_me_link = 'http://fav.me/d9kzjwb'
    direct_link = 'https://api-da.wixmp.com/_api/download/file?downloadToken=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsImV4cCI6MTU2MDY0ODA0MiwiaWF0IjoxNTYwNjQ3NDMyLCJqdGkiOiI1ZDA1OTcxMjY1YzI4Iiwib2JqIjpudWxsLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdLCJwYXlsb2FkIjp7InBhdGgiOiJcL2ZcLzRiZGVkZDgxLTY5MzYtNDRhMi1iMWFhLTZjYWQyZjZjNmQ3MlwvZDlremp3Yi0zY2E4N2I5ZC05ZThmLTQ5MjAtYTU0Ni0wMmFhOTk5YWE3MzAucG5nIiwiYXR0YWNobWVudCI6eyJmaWxlbmFtZSI6Im9yYW5nZV9qdWljZV9ieV9qb2V5aDNfZDlremp3Yi5wbmcifX19.YKSU2ofoOcvMFVXvVnG4boj8vl5sr3spbjhVAvTwS4g'
    VCR.use_cassette('scraper-fav-me-link', serialize_with: :compressed) do
      response = Booru::Scraper.scrape(fav_me_link)
      expected = Booru::ScraperResult.new(
        source_url:  'https://www.deviantart.com/joeyh3/art/Orange-Juice-579446651',
        author_name: 'joeyh3',
        description: "\"Ah can explain! This ain't what it looks like!\"",
        images:      response.images
      )
      assert_equal response, expected
      assert_equal response.images[0].url, direct_link
    end
  end

  test 'should fetch tumblr posts' do
    tumblr_link = 'https://overlordneon.tumblr.com/image/166653892311'

    VCR.use_cassette('scraper-tumblr-post', serialize_with: :compressed) do
      direct_link = 'https://66.media.tumblr.com/ca39c830ca366a9429cb4d1285b0fa25/tumblr_oy75t6pDbw1rf7j49o1_1280.jpg'
      response = Booru::Scraper.scrape(tumblr_link)
      expected = Booru::ScraperResult.new(
        source_url:  tumblr_link,
        author_name: 'overlordneon',
        description: "\u201cSunlight Biker AU\u201d as requested from Patreon~  \n\nPatreon // DeviantArt // Twitter // COMMISSIONS",
        images:      response.images
      )
      assert_equal response, expected
      assert_equal response.images[0].url, direct_link
    end
  end
end
