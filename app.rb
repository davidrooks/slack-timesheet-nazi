require 'sinatra/activerecord'
require 'sinatra'
require 'json'
require 'date'
require 'active_support/core_ext/hash/indifferent_access'


set :database, {adapter: "sqlite3", database: "timesheet_nazi.sqlite3"}


ActiveRecord::Schema.define do
  if !ActiveRecord::Base.connection.tables.include? 'offenders'
    create_table :offenders do |t|
      t.column :list, :string
    end
  end
end

class Offender < ActiveRecord::Base
end



WARNINGS = 3

before do
  @res = Offender.all
  if @res.count == 0
    @res = Offender.create(:list => {})
  else
    @res = @res.first
  end

  @offenders = eval(@res[:list])

end


get '/' do
  offence ["@sefton", "@zander"]
end

get '/test' do
  halt 200, 'offenders = ' + @offenders.to_json
end


post '/' do
  if ENV['USERS']
    if !ENV['USERS'].split(',').include?(params['user_name'])
      unauthorised
    end
  end
  users = params['text'].split
  if users.size == 0
    remind
  else
    offence users
  end
end

def unauthorised
  res = {}
  res["text"] = "Nice try! No soup for you."
  halt 200, {'Content-Type' => 'application/json'}, res.to_json
end

def remind
  res = {}
  if ENV['SEND_TO'] && ENV['SEND_TO'].upcase == 'ALL'
    res["response_type"] = "in_channel"
  end
  res["text"] = "@channel - timesheet reminder!"
  halt 200, {'Content-Type' => 'application/json'}, res.to_json
end

def offence(users)
  users.each do |user|
    if @offenders.has_key? user.to_sym
      if  !@offenders[user].include?(Date.today.to_s)
        @offenders[user.to_sym] << Date.today.to_s
      end
    else
      @offenders[user.to_sym] = []
      @offenders[user.to_sym] << Date.today.to_s
    end
  end

  res = {}
  if ENV['SEND_TO'] && ENV['SEND_TO'].upcase == 'ALL'
    res["response_type"] = "in_channel"
  end
  res["text"] = "Timesheets please #{params['text']}"
  res["attachments"] = []

  @offenders.each do |key,val|
    tmp = {}
    bad = {}
    if val.size == WARNINGS
      tmp["color"] = "danger"
      tmp["fields"] = []
      bad["title"] = ":cop: Penalty!"
      bad["value"] = 'Oh oh! ' + key.to_s + ' you have not done your timesheet AGAIN and will seek redemption by ' + punishment
      bad["short"] = false
      tmp["fields"] << bad
      res['attachments'] << tmp
      @offenders[key] = []
    elsif val.size == WARNINGS-1
      tmp["color"] = "warning"
      tmp["fields"] = []
      bad["title"] = ":bomb: Warning!"
      bad["value"] = key.to_s + ' you have not done your timesheet again and are on your last warning. Next time you will be penalised. You have been warned.'
      bad["short"] = false
      tmp["fields"] << bad
      res['attachments'] << tmp
    end
  end

  halt 200, {'Content-Type' => 'application/json'}, res.to_json
end

def punishment
  punishments = [
      'buying the team some cakes.',
      'spending a day wearing the hat of shame.',
  ]

  return punishments[rand(punishments.size)]
end

after do
  @res[:list] = @offenders.to_json
  @res.save
end


