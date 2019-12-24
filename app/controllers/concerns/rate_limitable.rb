# frozen_string_literal: true

module RateLimitable
  def ratelimit(limit, time, error)
    return if Rails.env.test?

    data = [
      current_user&.id,
      request.remote_ip,
      params[:controller],
      params[:action]
    ]

    key = "rl-#{Zlib.crc32(data.join(''))}"

    # pipelined returns [1, true]
    amt, = $redis.pipelined do
      $redis.incr key              # set/incr key
      $redis.expire key, time.to_i # bump expiry
    end

    return if amt.to_i <= limit

    respond_to do |format|
      format.json { render json: {}, status: :too_many_requests }
      format.any { redirect_back flash: { notice: error } }
    end
  end
end
