module Crud
  # create or update a record
  def create_or_update_record(name, arr)
    plural_name = name.pluralize
    ids  = $redis.zrange("#{name}:ids", 0, -1, withscores: true).to_h
    id, sort = ids.keys.max.to_i+1, ids.values.max.to_i+1 if params[:id].empty?
    data = {}
    arr.each { |item| data[item] = params[item.to_sym] }
    # values = arr.map{ |item| params[item.to_sym] }
    # data = arr.zip(values).to_h
    data["id"] = Integer(params[:id]) rescue id
    # begin
    $redis.zadd("#{name}:ids", sort, id) if params[:id].empty?
    $redis.hmset(plural_name, "#{name}:#{data['id']}", data)
    # rescue
    #   # logger.info "store data failed"
    #   $redis.zrem("#{name}:ids", id) if params[:id].empty?
    #   $redis.hdel(plural_name, "#{name}:#{data['id']}")
    # end
    redirect("/admin/#{plural_name}")
  end

  # delete a record
  def delete_record(name, id)
    plural_name = name.pluralize
    $redis.hdel(plural_name, "#{name}:#{id}")
    $redis.zrem("#{name}:ids", id)
    redirect("/admin/#{plural_name}")
  end

  def set_data(name)
    singular_name = name.singularize
    instance_name = "@#{name}"
    ids = $redis.zrange("#{singular_name}:ids", 0, -1)
    values = $redis.hgetall(name).values.map!{|item| eval item }.sort_by { |a| ids.index(a['id'].to_s) }
    instance_variable_set(instance_name, values)
  end
end
