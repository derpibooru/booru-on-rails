# frozen_string_literal: true

# Provides a +request_attributes+ method for actions that handle
# +UserAttributable+ objects. It returns a hash that can be inserted into params
# or passed directly via assign_attributes/update_attributes.
module UserAttribution
  def request_attributes
    {
      ip:          request.remote_ip,
      fingerprint: request.cookies['_ses'],
      user_agent:  request.env['HTTP_USER_AGENT'],
      referrer:    request.referer,
      user:        current_user
    }
  end
end
