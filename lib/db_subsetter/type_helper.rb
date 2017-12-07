module DbSubsetter
  # Utility module to help safely serialize types
  # FIXME: nothing about this seems named correctly
  module TypeHelper
    def self.cleanup_types(row)
      row.map do |field|
        case field
        when Date, Time then field.to_s(:db)
        else
          field
        end
      end
    end
  end
end
