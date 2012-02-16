source 'https://rubygems.org'

gemspec

platform :ruby_18 do
  gem "sequel", "3.28.0"
end

case ENV["DB"]
when "mysql"
  gem "mysql2"
when "postgres"
  gem "pg"
else
  gem "sqlite3"
end
