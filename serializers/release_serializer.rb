# frozen_string_literal: true

require_relative './track_serializer.rb'

class ReleaseSerializer < Blueprinter::Base
  identifier :id

  fields :title, :year, :romaji, :release_type

  view :extended do
    fields :cover
    field(:folders) { |release| release.folders.pluck(:id) }

    association :tracks, blueprint: TrackSerializer do |release|
      release.tracks.sort
    end
  end
end
