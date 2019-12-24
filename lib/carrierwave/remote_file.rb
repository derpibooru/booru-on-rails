# frozen_string_literal: true

module RemoteFileExtension
  # Quick and dirty hack to get rid of Twitter's original image url prefix
  def original_filename
    super.gsub(/:orig$/, '')
  end
end
class CarrierWave::Uploader::Download::RemoteFile
  prepend RemoteFileExtension
end
