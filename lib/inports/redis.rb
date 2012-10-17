class Redis
  require 'digest/md5'

  # Helper for getting and incrementing node id
  # value and returning a derived hash.

  def get_id
    $r.incr 'idcount'
    id = $r.get 'idcount'
    Digest::MD5.hexdigest('not a date :D' + id )
  end


  # Helper for keeping track of all our keys
  # in the "keys" list.

  def log_key(k)
    $r.rpush 'keys', k
  end


  # Removes all keys referenced in 'keys' list.
  #
  # Yields each key as it runs.

  def kill_keys
    $r.lrange('keys', 0, -1).each do |k|

      yield k if block_given?

      $r.del k
    end

    $r.del 'post_process'
    $r.del 'keys'

    # Attempt to delete unhandled sets in the event of a broken run.
    5.times {|i| $r.del "unhandled-#{i}"}
  end
end



# Initialize redis.
$r = Redis.new
$r.select CONFIG['db']

# Set node id incrementer to our safe offset.
$r.set 'idcount', CONFIG['ids']['start']

# Set input directory path as having the eZPublish homepage remote id.
$r.hset CONFIG['directories']['input'], 'id', CONFIG['ids']['homepage']

# Set media folders paths as having the appropriate remote ids.
$r.hset 'media:files:.', 'id', CONFIG['ids']['files']
$r.hset 'media:images:.', 'id', CONFIG['ids']['images']
