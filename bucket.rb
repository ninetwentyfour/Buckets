%w(rubygems sinatra liquid resolv open-uri haml pony).each{ |g| require g }

def solve params
  # get input as list of integers (#buckets, buckets sizes, target)
  gets = "2, #{params[:bucket1]}, #{params[:bucket2]}, #{params[:target]}"
  input = gets.split(/,/).map{|s| s.to_i}

  count = input.shift
  start = (1..count).map{[input.shift, 0]} #map each input into an array starting with 0 (empty)
  target = input.shift

  # a bucket configuration is a list of buckets, each represented as
  # array [denomination, fill level], i.e. initial configurations
  # is e.g. [[3, 0], [5, 0]] for empty buckets of size 3 and 5

  configurations = {start => ""}
  step = 0
  solution = nil
  #check it two buckets add to target - easy to solve
  if params[:bucket1].to_i + params[:bucket2].to_i == params[:target].to_i
    solution = "Fill both buckets."
    step = 1
    configurations[solution] = "Fill both buckets."
  end

  current = configurations.keys

  while current.size > 0 and solution == nil do

    # test current configurations if target amount is included in a bucket
    solution = current.select{|k| k.any?{|b| b[1] == target}}[0]  
    break if solution

    step += 1
    new_configurations = {}

    # for all configurations for all buckets
    current.each{|k|
      k.size.times{|i|

        # do a fill operation on this bucket
        kn = Marshal.load(Marshal.dump(k))   # make deep copy
        # increase fill level to bucket denomination
        kn[i][1] = kn[i][0]
        new_configurations[kn] = "#{configurations[k]} Fill #{kn[i][0]}"

        # do an empty operation on this bucket
        kn = Marshal.load(Marshal.dump(k))   # make deep copy
        # set fill level to zero
        kn[i][1] = 0
        new_configurations[kn] = "#{configurations[k]} Empty #{kn[i][0]}"

        # do a move operation on any other bucket
        k.size.times{|j|
          kn = Marshal.load(Marshal.dump(k))   # make deep copy
          # amount movable is current amount or space left in other bucket
          h = [kn[i][1], kn[j][0]-kn[j][1]].min   
          kn[i][1] -= h
          kn[j][1] += h
          new_configurations[kn] = "#{configurations[k]} Move #{kn[i][0]} to #{kn[j][0]}"
        }
      }
    }

    # remove any configuration already reachable with less steps
    new_configurations.keep_if{|conf| !configurations[conf]}

    # merge new configurations
    configurations.merge!(new_configurations)

    current = new_configurations.keys

  end

  if solution
    return "Solution found with #{step} steps: #{configurations[solution]}"
  else
    return "Impossible to reach target"
  end
end


def valid_email?(email)
  if email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
    domain = email.match(/\@(.+)/)[1]
    Resolv::DNS.open do |dns|
        @mx = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
    end
    @mx.size > 0 ? true : false
  else
    false
  end
end

def valid_bucket?(bucket)
  if bucket.to_i < 0
    false
  else
    true
  end
end

def solveable?(bucket1, bucket2, target)
  if target.to_i > bucket1.to_i + bucket2.to_i
    false
  else
    true
  end
end

def given? field
  !field.empty?
end

def validate params
  errors = {}

  # [:bucket1, :bucket2, :target, :email].each{|key| params[key] = (params[key] || "").strip }
  # 
  if given? params[:bucket1]
    errors[:bucket1]   = "You can't have a bucket with a size less than 0" unless valid_bucket? params[:bucket1]
  else
    errors[:bucket1]   = "This field is required"
  end
  
  if given? params[:bucket2]
    errors[:bucket2]   = "You can't have a bucket with a size less than 0" unless valid_bucket? params[:bucket2]
  else
    errors[:bucket2]   = "This field is required"
  end
  
  if given? params[:target]
    errors[:target]   = "This is not solveable" unless solveable?(params[:bucket1],params[:bucket2],params[:target])
  else
    errors[:target]   = "This field is required"
  end
  
  if given? params[:email]
    errors[:email]   = "Please enter a valid email address" unless valid_email? params[:email]
  end


  errors
end

def send_email params, solution
  email_template = <<-EOS
  Sent via http://bucket-solver.herokuapp.com/ 
  A solution for your bucket problem has been found:     {{ solution }}
  EOS

  body = Liquid::Template.parse(email_template).render  "solution"       => "#{solution}"

  Pony.options = {
    :via => :smtp,
    :via_options => {
      :address => 'smtp.sendgrid.net',
      :port => '587',
      :domain => 'heroku.com',
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  }

  Pony.mail(:to => "#{params[:email]}", :from => "contact@travisberry.com", :subject => "Bucket Solution Found", :body => body)
end


get '/?' do
  @errors, @values, @sent = {}, {}, false
  haml :bucket_form
end

post '/bucket-solved/?' do
  @errors     = validate(params)
  @values     = params

  if @errors.empty?
    begin
      @solution = solve(params)
      if given? params[:email]
        send_email(params, @solution) 
      end
      @sent = true
  
    rescue Exception => e
      puts e
      @failure = "Ooops, it looks like something went wrong while attempting to send your email. Mind trying again now or later? :)"
    end
  end

  haml :bucket_solved
end