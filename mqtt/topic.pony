primitive MQTTTopic
  """
  An utility to validate topics upon publishing or subscribing.
  """

  fun tag validate_publish(topic: String): Bool =>
    """
    Validates a PUBLISH topic, by verifying if it has no wildcard (`#` or `+`)
    or null characters. Returns `true` if the topic is valid and `false`
    otherwise.
    """
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    not(topic.contains("#"))
      and not(topic.contains("+"))
      and not(topic.contains(String.from_array([0x00])))

  fun tag validate_subscribe(topic: String): Bool =>
    """
    Validates a SUBSCRIBE/UNSUBSCRIBE filter, by verifying if it has wildcards
    properly positioned between dashes (`#` or `+`) and no null characters.
    Returns `true` if the topic is valid and `false` otherwise.
    """
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    if topic.contains(String.from_array([0x00])) then return false end
    var was_slash: Bool = true
    var was_plus: Bool = false
    var was_hash: Bool = false
    for byte in topic.values() do
      if was_hash or (was_plus and (byte != '/')) then
        return false
      elseif byte == '/' then
        was_slash = true
        was_plus = false
      elseif byte == '+' then
        if not was_slash then return false end
        was_slash = false
        was_plus = true
      elseif byte == '#' then
        if not was_slash then return false end
        was_hash = true
      else
        was_slash = false
      end
    end
    true

  fun tag match_topic(topic: String, filter: String): Bool =>
    """
    Checks if the provided PUBLISH topic in `name` matches the provided
    SUBSCRIBE/UNSUBSCRIBE filter in `filter` and if they are both valid.
    Returns `true` if the topic matches the filter and `false` otherwise.
    """
    if validate_publish(topic) and validate_subscribe(filter) then
      let topic_array: Array[String] val = topic.split_by("/")
      let filter_array: Array[String] val = filter.split_by("/")
      if topic_array.size() < filter_array.size() then
        return false
      elseif topic_array.size() > filter_array.size() then
        try
          if filter_array(filter_array.size() - 1)? != "#" then
            return false
          end
        end
      end
      for i in filter_array.keys() do
        try
          let multi_wc = filter_array(i)? == "#"
          let single_wc = filter_array(i)? == "+"
          let equal_level = filter_array(i)? == topic_array(i)?
          if (i == 0) and (topic_array(0)?(0)? == '$') then
            if single_wc or multi_wc or not(equal_level) then
              return false
            end
          elseif multi_wc then
            return true
          elseif not(single_wc) and not(equal_level) then
            return false
          end
        else
          false
        end
      end
      true
    else
      false
    end
