Sequel::Model.class_eval do
  yaml_as "tag:ruby.yaml.org,2002:Sequel"

  def self.yaml_new(klass, tag, val)
    res = klass[val['values'][klass.primary_key]] 
    $stdout.puts "yaml_new: #{klass}, #{tag}, #{val} => res: #{res.inspect}"
    res || raise(Delayed::DeserializationError, "Sequel Record not found, class: #{klass} , primary key: #{val['values'][klass.primary_key]}")
  rescue Exception
    $stdout.puts "#{$!.inspect}"
  end

  def to_yaml_properties
    ['@values']
  end
end
