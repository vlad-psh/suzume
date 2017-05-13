class Artist < ActiveRecord::Base
  has_and_belongs_to_many :albums
  has_and_belongs_to_many :tags
end

class Album < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :tags
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :albums
end
