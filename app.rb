require 'sinatra'
require 'json'
require 'date'

WARNINGS = 3

before do
  if File.exists? 'offenders.txt'
    @offenders = eval(File.read('offenders.txt'))
    if @offenders.nil?
      @offenders = {}
    end
  else
    @offenders = {}
  end
end


get '/' do
  halt 200, 'app running'
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
    if @offenders.has_key? user
      if  !@offenders[user].include?(Date.today.to_s)
        @offenders[user] << Date.today.to_s
      end
    else
      @offenders[user] = []
      @offenders[user] << Date.today.to_s
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
      bad["value"] = 'Oh oh! ' + key + ' you have not done your timesheet AGAIN and will seek redemption by ' + punishment
      bad["short"] = false
      tmp["fields"] << bad
      res['attachments'] << tmp
      @offenders[key] = []
    elsif val.size == WARNINGS-1
      tmp["color"] = "warning"
      tmp["fields"] = []
      bad["title"] = ":bomb: Warning!"
      bad["value"] = key + ' you have not done your timesheet again and are on your last warning. Next time you will be penalised. You have been warned.'
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
  File.open('offenders.txt', 'w') { |file| file.write(@offenders) }
end


