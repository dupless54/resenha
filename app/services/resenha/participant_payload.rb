# frozen_string_literal: true

module Resenha
  class ParticipantPayload
    def self.build(user, scope:, metadata: nil)
      BasicUserSerializer
        .new(user, scope: scope, root: false)
        .as_json
        .merge(metadata || {})
        .merge(staff: user.staff?)
    end
  end
end
