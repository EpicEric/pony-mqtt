use "regex"

primitive MQTTTopic
  """
  An utility to validate topics upon publishing or subscribing.
  """
  fun tag validate_publish(topic: String): Bool =>
    """
    Valid PUBLISH topics do not contain '#' or '+'.
    """
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    not(topic.contains("#"))
      and not(topic.contains("+"))
      and not(topic.contains(String.from_array([0x00])))

  fun tag validate_subscribe(topic: String): Bool =>
    """
    Valid SUBSCRIBE/UNSUBSCRIBE topics may include isolated '#' or '+'
    between forward dashes.
    """
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    if topic.contains(String.from_array([0x00])) then return false end
    try
      let r = 
        Regex("^(#|(([^#\\/\\+]*|\\+)?(\\/([^#\\/\\+]*|\\+))*(\\/#)?))$")?
      r == topic
    else
      false
    end

  fun tag match_topic(name: String, filter: String): Bool =>
    """
    Check if the topic name matches the topic filter and they are both valid.
    """
    if validate_publish(name) and validate_subscribe(filter) then
      let name_array: Array[String] val = name.split_by("/")
      let filter_array: Array[String] val = filter.split_by("/")
      if name_array.size() < filter_array.size() then
        return false
      elseif name_array.size() > filter_array.size() then
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
          let equal_level = filter_array(i)? == name_array(i)?
          if (i == 0) and (name_array(0)?(0)? == '$') then
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
