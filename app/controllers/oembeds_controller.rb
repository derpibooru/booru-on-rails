# frozen_string_literal: true

class OembedsController < ApplicationController
  skip_authorization_check

  def show
    uri = URI(URI.decode_www_form_component(params[:url].tr(' ', '+'))) rescue nil
    return head(:bad_request) unless uri

    # /img/view/2014/6/12/651690__safe_solo_pinkie+pie_solo+female_artist+needed_sneezing_allergies_pollen.png
    # /img/2014/6/11/650526/large.png
    id = uri.path.match(/\/img\/.*\/(\d+)(\.|[\/_][_\w])/)[1] rescue nil
    # /17842
    # /images/1245
    id ||= uri.path.match(/\/(\d+)/)[1] rescue nil

    @image = Image.find(id)
    name = I18n.t('booru.name')
    site = I18n.t('booru.site')

    @data = {
      version:             '1.0',
      type:                'photo',
      title:               "##{@image.id} - #{@image.tag_list} - #{name}",
      author_url:          @image.source_url.presence,
      author_name:         ((@image.tags.detect { |t| t.name.include?('artist:') }.name.split(':')[1]) rescue 'Unknown Artist'),
      provider_name:       name,
      provider_url:        "#{Booru::CONFIG.settings[:public_url_root]}/#{@image.id}",
      cache_age:           7200,
      "#{site}_id" =>       @image.id,
      "#{site}_score" =>    @image.score,
      "#{site}_comments" => @image.comments_count,
      "#{site}_tags" =>     @image.tags.pluck(:name)
    }

    if params[:maxwidth] && params[:maxheight]
      width = params[:maxwidth].to_i
      height = params[:maxheight].to_i
      @data[:thumbnail_url] = @image.image.url([width, height])
    else
      @data[:thumbnail_url] = @image.image.pretty_url
    end

    respond_to do |format|
      format.html { redirect_to image_path(@image) }
      format.json { render json: @data }
      format.xml  {}
    end
  end
end
