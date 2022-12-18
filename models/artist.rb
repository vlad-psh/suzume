# frozen_string_literal: true

class Artist < ActiveRecord::Base
  has_many :releases
  has_many :tracks, through: :releases
  has_and_belongs_to_many :tags

  def sorted_tracks
    result = {}
    rr = tracks.includes(:release)

    prev_release = nil
    rr.sort_by {|rec| "#{rec.release.year}#{rec.release.title}"}.each do |r|
      result[r.release] ||= []
      result[r.release] << r
    end

    return result
  end
end
