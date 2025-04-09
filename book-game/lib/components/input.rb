module Components
  class Input
    # No data needed yet; just marks an entity as input-responsive
    def to_h
      {}
    end

    def self.from_h(_hash)
      new
    end
  end
end
