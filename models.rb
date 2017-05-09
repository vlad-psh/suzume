class Artist < ActiveRecord::Base
  has_and_belongs_to_many :albums
  has_and_belongs_to_many :tags
end

class Album < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :tags

  def both_types
    if primary_type && !primary_type.empty?
      if secondary_type && !secondary_type.empty?
        return "#{primary_type} + #{secondary_type}"
      else
        return primary_type
      end
    else
      if secondary_type && !secondary_type.empty?
        return secondary_type
      else
        return "NO TYPE"
      end
    end
  end

  def fix_date
    if date.nil?
      return ''
    elsif date.year >= 2030
      return ''
    elsif date.month == 12 && date.day == 31
      return date.year.to_s
    else
      return date.to_s
    end
  end
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :albums
end
