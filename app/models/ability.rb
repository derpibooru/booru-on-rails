# frozen_string_literal: true

class Ability < Can4::Ability
  def initialize(user, ip = nil)
    user ||= User.new # guest user (not logged in)
    registered_user = user.persisted?

    if user.role == 'admin'
      allow_anything!
    else
      can :read, Image
      can :create, Image
      can :update_metadata, Image do |image|
        image.visible_to?(user) && image.tag_editing_allowed
      end
      can :read, Tag
      can :read, Gallery
      can :read, Comment do |comment|
        !comment.hidden_from_users
      end
      can :create, Comment
      can :read, DuplicateReport
      can :create, DuplicateReport
      can :read, Filter do |f|
        f.system? || f.public? || (registered_user ? f.user_id == user.id : false)
      end
      can :create, Report
      can :read, Forum do |forum|
        forum.visible_to?(user)
      end
      can :read, Topic do |topic|
        topic.forum.visible_to?(user)
      end
      can :create, Topic do |topic|
        topic.forum.visible_to?(user)
      end
      can :read, Post do |post|
        !(post.hidden_from_users || post.topic.hidden_from_users) && post.topic.forum.visible_to?(user)
      end
      can :create, Post do |post|
        !post.topic.hidden_from_users && post.topic.locked_at.nil? && post.topic.forum.visible_to?(user)
      end
      can :read, DnpEntry do |dnp|
        dnp.listed? || user == dnp.requesting_user
      end
      can :read, Badge
      can :read, User
      can :read, LivestreamChannel
      can :read, PicartoChannel

      if registered_user
        allow_registered_user_actions!(user, ip)
        if user.staff?
          allow_staff_actions!(user)
          allow_assistant_actions!(user) if user.role == 'assistant'
          allow_mod_actions!(user) if user.role == 'moderator'
        end
      end
    end
  end

  def allow_registered_user_actions!(user, ip)
    can :update, Image do |image|
      image.uploader_is?(user, ip) && !image.hidden_from_users
    end
    can :edit, Post do |post|
      post.user && post.user_id == user.id && !post.hidden_from_users && !post.topic.hidden_from_users && post.topic.locked_at.nil?
    end
    can :edit, Comment do |comment|
      can?(:read, comment) && comment.user == user && (comment.created_at > 15.minutes.ago)
    end
    can :create, Filter
    can :edit, Filter do |f|
      f.user_id == user.id
    end
    can :delete, Filter do |f|
      f.user_id && f.user_id == user.id && f.user_count == 0
    end
    can :create, Gallery
    can :edit, Gallery do |gallery|
      gallery.creator == user
    end
    can :create, Commission
    can :edit, Commission do |c|
      user.persisted? && c.user_id == user.id
    end
    can :create, DnpEntry do
      user.linked_tags.present?
    end
    can :rescind, DnpEntry do |dnp|
      dnp.requesting_user_id == user.id
    end
    can :create, Conversation
    can :read, Conversation do |conv|
      conv.from_id == user.id || conv.to_id == user.id
    end
    can :bulk_update, Conversation
    can :create, UserLink
    can :read, UserLink do |ul|
      ul.user_id == user.id
    end
    can :create, Poll if !user.has_cached_role? :abuses, Poll
    can :create, PollVote if !user.has_cached_role? :abuses, PollVote
  end

  def allow_staff_actions!(user)
    can :manage, ModNote
    if user.has_cached_role? :batch_update, Tag
      can :update_metadata, Image
      can :batch_update, Tag
    end
  end

  def allow_assistant_actions!(user)
    if user.has_cached_role? :moderator, Image
      can :hide, Image
      can :undelete, Image
      can :repair, Image
      can :update, Image
      can :edit_scratchpad, Image
    end
    if user.has_cached_role? :moderator, DuplicateReport
      can :manage, DuplicateReport
      can :update, Image # copying descriptions over
      can :hide, Comment # deleting "DUUUPE" comments before merging
    end
    if user.has_cached_role? :moderator, Comment
      can :read, Comment
      can :hide, Comment
      can :edit, Comment
      can :restore, Comment
    end
    if user.has_cached_role? :moderator, Topic
      can :assist, Topic
      can :lock, Topic
      can :unlock, Topic
      can :stick, Topic
      can :unstick, Topic
      can :move, Topic
      can :hide, Topic
      can :restore, Topic
      can :destroy, Topic
      can :create, Post
      can :assist, Post
      can :read, Post
      can :hide, Post
      can :restore, Post
      can :review, Post
      can :edit, Post
    end
    can :update, Tag if user.has_cached_role? :moderator, Tag
    can :manage, UserLink if user.has_cached_role? :moderator, UserLink
  end

  def allow_mod_actions!(user)
    can :manage, Image
    can :manage, TagChange
    can :manage, SourceChange
    can :manage, Gallery
    can :manage, Comment
    can :manage, Report
    can :manage, DuplicateReport
    can :read, Forum # access any forum regardless of its visibility
    can :manage, Topic
    can :manage, Poll
    can :manage, Post
    can :manage, Channel
    can :manage, Conversation
    can :manage, Filter
    can :mod_read, Tag
    can :update, Tag
    can :mod_read, User
    can :manage, UserBan
    can :manage, SubnetBan
    can :manage, FingerprintBan if user.has_cached_role? :ban_competent
    can :manage, UserWhitelist
    can :manage, UserLink
    can :mod_read, Badge
    can :manage, BadgeAward
    can :award, Badge
    can :remove, Badge
    can :manage, Commission
    can :manage, DnpEntry
    can :manage, User if user.has_cached_role? :moderator, User
    can :twofactor, User if user.has_cached_role? :twofactor, User
    if user.has_cached_role? :admin, Tag
      can :manage, Tag
      can :manage, ActiveJob
    end
    can :manage, SiteNotice if user.has_cached_role? :admin, SiteNotice
    can :manage, Badge if user.has_cached_role? :admin, Badge
    can :manage, Role if user.has_cached_role? :admin, Role
    can :manage, Flipper if user.has_cached_role? :flipper
    can :manage, Advert if user.has_cached_role? :admin, Advert
  end
end
