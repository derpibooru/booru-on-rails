# frozen_string_literal: true

class UserLogger < LoggerBase
  def self.log(status, user, mod = nil)
    s = +"[USER: #{status}] on #{user&.name}"
    s += " by #{mod.name}" if mod

    modfeed_send(s)
  end

  def self.log_role(old_role, new_role, user, mod = nil)
    s = +"[USER: Role Changed] on #{user&.name}"
    s += " by #{mod.name}." if mod
    s += if new_role != 'user'
      " #{old_role.capitalize} to #{new_role.capitalize}."
    else
      " Demoted to User from #{old_role.capitalize}."
    end

    modfeed_send(s)
  end
end
