# frozen_string_literal: true

class SerializableNotification < JSONAPI::Serializable::Resource
  type 'notifications'
  attributes :action, :actor_id, :actor_type, :actor_child_id, :actor_child_type
end
