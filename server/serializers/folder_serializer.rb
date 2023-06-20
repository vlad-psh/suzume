# frozen_string_literal: true

require_relative './release_serializer.rb'

class FolderSerializer < Blueprinter::Base
  identifier :id

  fields :path, :is_symlink
  field(:artist) { |folder| folder.release ? [folder.release.artist.id, folder.release.artist.title] : nil }
  field(:files) { |folder| folder.contents[:files] }
  field(:name) { |folder| (folder.is_symlink ? '🔗' : '') + folder.name }
  field(:parents) { |folder| folder.parents.map{|i| [i.id, (folder.is_symlink ? '🔗' : '') + File.basename(i.path)]} }
  field(:subfolders) do |folder|
    folder.contents[:dirs].map do |f|
      {
        id: f.id,
        title: (f.is_symlink ? '🔗' : '') + f.path,
        artist: f.release ? { id: f.release.artist_id, title: f.release.artist.title } : nil
      }
    end
  end

  association :release, blueprint: ReleaseSerializer, view: :extended
end
