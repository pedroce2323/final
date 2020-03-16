# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"
require "geocoder"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

trips_table = DB.from(:trips)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)


before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and list of trips (aka "index")
get "/" do
    puts "params: #{params}"

    @trips = trips_table.all.to_a
    view "trips"
end

# trip details (aka "show")
get "/trips/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @trip = trips_table.where(id: params[:id]).to_a[0]
    @reviews = reviews_table.where(trip_id: @trip[:id]).to_a
    @review_count = reviews_table.where(trip_id: @trip[:id]).count #check this out later

    @results = Geocoder.search(@trip[:title])
    @lat_long = @results.first.coordinates # => [lat, long]
    @coordinates = "#{@lat_long[0]} #{@lat_long[1]}"
    

    view "trip"
end

# sign up to get text updates
get "/trips/:id/SMS" do
    puts "params: #{params}"

       account_sid = ENV["TWILIO_ACCOUNT_SID"]
       auth_token = ENV["TWILIO_AUTH_TOKEN"]
       client = Twilio::REST::Client.new(account_sid, auth_token)
       client.messages.create(
       from: "+14243487854",
       to: "+14107036254",
       body: "Thanks for signing up to receive updates for this KWEST")

    @trip = trips_table.where(id: params[:id]).to_a[0]
    view "text_signup"
end

# display the review form (aka "new")
get "/trips/:id/reviews/new" do
    puts "params: #{params}"

    @trip = trips_table.where(id: params[:id]).to_a[0]
    view "new_review"
end

# receive the submitted review form (aka "create")
post "/trips/:id/reviews/create" do
    puts "params: #{params}"

    # first find the trip that we're reviewing
    @trip = trips_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the reviews table with the review form data
    reviews_table.insert(
        trip_id: @trip[:id],
        user_id: session["user_id"],
        year: params["year"],
        rating: params["rating"],
        comments: params["comments"],
    )
    view "create_review"
end


get "/reviews/:id/edit" do
    puts "params: #{params}"

    @review = reviews_table.where(id: params["id"]).to_a[0]
    @trip = trips_table.where(id: @review[:trip_id]).to_a[0]
    view "edit_review"
end

post "/reviews/:id/update" do
    puts "params: #{params}"

    # first find the review that we're editing
    @review = reviews_table.where(id: params[:id]).to_a[0]
    # find relevant event based on review trip_id
    @trip = trips_table.where(id: @review[:trip_id]).to_a[0]
    # next we want to update reviews table with the review edited data
    reviews_table.where(id: params["id"]).update(
        year: params["year"],
        rating: params["rating"],
        comments: params["comments"]
    )

    view "update_review"
end

# delete a review (aka "destroy")
get "/reviews/:id/destroy" do
    puts "params: #{params}"

    review = reviews_table.where(id: params["id"]).to_a[0]
    @trip = trips_table.where(id: review[:trip_id]).to_a[0]

    reviews_table.where(id: params["id"]).delete

    view "destroy_review"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    users_table.insert(
        name: params["name"],
        phonenum: params["phonenum"],
        email: params["email"],
        password: BCrypt::Password.create(params["password"])
    )
    view "create_user"
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]
    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    view "logout"
end