# frozen_string_literal: true

# A concern defining +load_user+ method for controllers
# operating on user profiles (receiving user id or slug as a request parameter).
# Set "before_action :user_query, except/only" in the controller and use
# +@user+ in method body.
# Override +user_param+ if the parameter name is other than +:id+
module UserQuery
  def user_param
    :id
  end

  def load_user
    authorize! :read, User
    @user = User.find_by_slug_or_id(params[user_param])
    redirect_to '/', alert: "Sorry, couldn't find that user!" if @user.nil?
  end
end
