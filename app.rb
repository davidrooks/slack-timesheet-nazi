require 'sinatra'
require 'json'
require 'date'

before do
  if File.exists? 'offenders.txt'
    @offenders = eval(File.read('offenders.txt'))
  else
    @offenders = {}
  end
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
  if ENV['SEND_TO'] == 'ALL'
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

  naughty_boys = @offenders.reject{|k,v| v.size < 3}

  res = {}
  if ENV['SEND_TO'] == 'ALL'
    res["response_type"] = "in_channel"
  end
  res["text"] = "Timesheets please #{params['text']}"
  res["attachments"] = []

  naughty_boys.each do |key,val|
    tmp = {}
    tmp["color"] = "danger"
    bad = {}
    tmp["fields"] = []
    bad["title"] = ":cop: Penalty!"
    bad["value"] = 'Oh oh! ' + key + ' has not done their timesheet AGAIN and will seek redemption by ' + punishment
    bad["short"] = false
    tmp["fields"] << bad
    res['attachments'] << tmp
    @offenders[key] = []
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


