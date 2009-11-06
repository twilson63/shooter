require 'sinatra'
require 'crack'
require 'sequel'
require 'haml'
require 'activesupport'

module Logs
  def self.data
    @@data ||= make
  end
  
  def self.make
    db = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://shooter.db')
    make_table(db)
    db[:logs]    
  end
  
  def self.make_table(db)
    db.create_table :logs do
      primary_key :id
      String :name, :null => false
      Time :date 
      String :provider
      String :patient
      Text :body
      
      Time :created_at
    end
  rescue Sequel::DatabaseError
    # assume table already exists
  end  
end

class Shooter < Sinatra::Default
  
  get '/' do
    if params[:q]
      @results = Logs.data.filter(:provider.like('params[:q]%')).all
    else
      @results = Logs.data.all
    end
    
    haml :index, :locals => { :results => @results }
  end
  
  post '/' do
    #decrypted_data = OpenSSL::PKG::RSA
    data = Crack::JSON.parse(request.body.read)
    #puts data.inspect
    Logs.data << { :name => "encounter", :provider => data["provider"], :patient => data["patient"], :body => data["body"].inspect }
  end
  
  get '/:id.xml' do
    content_type "application/xml", :charset => 'utf-8'
    puts Logs.data.filter(:id => params[:id]).first[:body]
    eval(Logs.data.filter(:id => params[:id]).first[:body]).to_xml
  end
end