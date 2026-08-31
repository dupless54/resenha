# frozen_string_literal: true

module Resenha
  class RoomBanEvictor
    def self.evict!(room:, user:)
      return unless Resenha::ParticipantTracker.user_ids(room.id).include?(user.id)

      metadata = Resenha::ParticipantTracker.get_metadata(room.id, user.id)
      session = Resenha::Session.find_by(id: metadata[:session_id]) if metadata[:session_id]
      session&.close!

      Resenha::ParticipantTracker.mark_left(room.id, user.id)
      Resenha::ParticipantTracker.remove(room.id, user.id)
      Resenha::UserStatusManager.clear_voice_status(user)
      Resenha::BadgeGranterHooks.on_leave(user, session, room: room)
      Resenha::RoomBroadcaster.publish_kick(room, user.id)
      Resenha::RoomBroadcaster.publish_participants(room)
      Resenha::Livekit::RoomServiceClient.remove_participant(room, user.id)

      session
    end
  end
end
