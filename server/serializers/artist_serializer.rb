# frozen_string_literal: true

require_relative './release_serializer.rb'

class ArtistSerializer < Blueprinter::Base
  identifier :id

  fields :title, :aliases, :romaji
  
  view :index do
    field(:title) { |a| a.romaji.present? ? "#{a.title} (#{a.romaji})" : a.title }
    # field(:tags) { |artist| artist.tags.pluck(:title) }
  end

  view :extended do
    association(:releases, blueprint: ReleaseSerializer, view: :extended) { |artist| ordered_releases(artist) }
  end

  view :autocomplete do
    association(:releases, blueprint: ReleaseSerializer, view: nil) { |artist| ordered_releases(artist) }
  end

  private

  def self.ordered_releases(artist)
    artist.releases.includes(:tracks, :folders).order(year: :desc)
  end
end
