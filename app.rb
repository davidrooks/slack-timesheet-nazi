require 'sinatra'
require 'json'

before do
  @offenders = eval(File.read('offenders.txt'))
end

post '/' do
  users = params['text'].split
  if users.size == 0
    remind
  else
    offence users
  end
end

def remind
  res = {}
  # res["response_type"] = "in_channel"
  res["text"] = "@channel - timesheet reminder!"
  halt 200, {'Content-Type' => 'application/json'}, res.to_json
end

def offence(users)
  users.each do |user|
    if @offenders.has_key? user
      @offenders[user] = @offenders[user] + 1
    else
      @offenders[user] = 1
    end
  end

  naughty_boys = @offenders.reject{|k,v| v < 3}

  res = {}
# res["response_type"] = "in_channel"
  res["text"] = "Timesheets please #{params['text']}"
  res["attachments"] = []

  naughty_boys.each do |key,val|
    tmp = {}
    tmp["color"] = "danger"
    tmp["thumb_url"] = ""
    bad = {}
    tmp["fields"] = []
    bad["title"] = "Penalty"
    bad["value"] = 'Oh oh! ' + key + ' has not done their timesheet again and will seek redemption by buying the team some cakes.'
    bad["short"] = false
    tmp["fields"] << bad
    res['attachments'] << tmp
    @offenders[key] = 0
  end

  halt 200, {'Content-Type' => 'application/json'}, res.to_json
end


after do
  File.open('offenders.txt', 'w') { |file| file.write(@offenders) }
end


