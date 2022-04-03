module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Mandated by FR-10: OwnerEdit.Canvas, FR-11: New.Canvas, FR-12: ParticipantEdit.Canvas

    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if env['warden']&.user
        env['warden'].user
      else
        reject_unauthorized_connection
      end
    end
  end
end
