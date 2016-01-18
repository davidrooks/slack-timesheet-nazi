require 'sinatra/base'
require 'json'
require 'date'
require 'rest-client'

class App < Sinatra::Base


  JSON_API = 'https://api.myjson.com/bins/2v9h1'

  WARNINGS = 3

  configure :production, :development do
    enable :logging
  end

  before do
    next unless request.post?
    res = JSON.parse(RestClient.get JSON_API, {:accept => :json})
    puts res

    @offenders = res.to_hash
    puts @offenders
  end

# pass json in body {'offenders' => [''@sefton', '@zander']}
  post '/test' do
    params = eval(request.body.read)
    puts params
    if !params.nil? && params['offenders']
      offence params['offenders']
    end
    halt 200, 'offenders = ' + @offenders.to_s
  end

  get '/' do
    halt 200, 'hello world'
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
        puts 'has key'
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
      if !users.include? key
        next
      end
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
    next unless request.post?
    puts @offenders
    RestClient.put JSON_API, @offenders.to_json, :content_type => 'application/json'
  end
end

