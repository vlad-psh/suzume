# frozen_string_literal: true

class TrackSerializer < Blueprinter::Base
  identifier :uid

  field(:title) { |track| track.title.presence || track.stripped_filename }
  field :original_filename, name: :filename
  field :duration_string, name: :dur
  fields :rating, :purged
  # field(:br) { |track| (track.mediainfo['br'].to_i / 1000).to_s + track.mediainfo['brm'] }
end
