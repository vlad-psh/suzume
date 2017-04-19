class Artist < ActiveRecord::Base
  has_and_belongs_to_many :albums
  has_and_belongs_to_many :tags
end

class Album < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :tags

  def both_types
    if self.secondary_type && !self.secondary_type.empty?
      return "#{primary_type} + #{secondary_type}"
    else
      return primary_type
    end
  end
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :albums
end
