# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :trips do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :location
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :trip_id
  foreign_key :user_id
  String :year
  String :rating
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  Integer :phonenum
  String :email
  String :password
  
end

# Insert initial (seed) data
trips_table = DB.from(:trips)

trips_table.insert(title: "Jamaica", 
                    description: "Fun in the sun, luxurious activities, and good vibes with new friends",
                    date: "August 22-29",
                    location: "Montego Bay, Ocho Rios, Negril")

trips_table.insert(title: "French Riviera", 
                    description: "Baguettes, Cheese, Vinyards, and good times in one of the most beautiful places on Earth",
                    date: "August 21-28",
                    location: "Nice, Cannes")

trips_table.insert(title: "Hawaii", 
                    description: "Get your snorkles ready!!! On KWEST Hawaii, you only eat what you catch",
                    date: "August 21-26",
                    location: "Honolulu, Maui")

puts "success!"