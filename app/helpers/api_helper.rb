module ApiHelper
  def search_sphinxql(query, page_count=1000)
    options = {:match_mode=>:extended, :index => 'idx1',:sql => { :select => 'id,ip,title,header,host,domain,lastupdatetime'},:per_page => page_count,:page => params['page'],:order => "lastupdatetime DESC"}#:retry_stale => 2,
    @results = ThinkingSphinx.search query,options
  end

  def search(query, page_count=10, page=1)
    @query = query
    @query_l = nil
    begin
      @query_l = SearchHelper::SphinxProcessor.parse(@query)
    rescue => e #Parslet::ParseFailed
      puts "QueryParser failed:"+e.inspect+e.backtrace.to_s
    end

    @results = nil
    begin
      options = {:index => 'idx1',:sql => { :select => 'id,ip,title,header,host,lastupdatetime'},:per_page => page_count, :page => page}#:retry_stale => 2,
      if @query_l
        @mode = "extended"
        options[:match_mode] = :extended
        options[:order] = "lastupdatetime DESC"
        @results = ThinkingSphinx.search @query_l,options
      else
        @mode = "normal"
        if @query.size>0
          options[:field_weights] = {
              :ip => 10000,
              :host => 400,
              :title => 50,
              :header    => 20,
              :body => 1
          }
        else
          options[:order] = "lastupdatetime DESC"
        end
        @results = ThinkingSphinx.search Riddle::Query.escape(@query),options
      end
      @tags = {}
      #if @results
      #  @results.each {|x|
      #    @tags[x.host] = Tag.find_by_host x.host
      #    @error, @msg = Userhost.add_user_host(current_user, x.host, '127.0.0.2')
      #    puts "error: #{@msg}" if @error
      #  }
      #end
    rescue ThinkingSphinx::SphinxError => e
      @error = e.to_s
    end
    [@error, @mode, @results, @tags]
  end

  def search_url(query, page, per_page=1000)
    @query = query
    @query_l = nil
    begin
      @query_l = SearchHelper::SphinxProcessor.parse(@query)
    rescue => e #Parslet::ParseFailed
      puts "QueryParser failed:"+e.inspect+e.backtrace.to_s
    end

    @results = nil
    begin
      @max_id = 1
      (1..page).each{|i|
        options = {:match_mode => :extended, :index => 'subdomain_core',
                   :with => {:id => @max_id..9999999999},
                   :sql => { :select => 'id,host'}, :per_page => per_page,
                   :page => 1, :order => "id asc"}
        if @query_l
          @mode = "extended"
          options[:match_mode] = :extended
          #options[:order] = "lastupdatetime DESC"
          @results = ThinkingSphinx.search @query_l,options
        else
          @mode = "normal"
=begin
          if @query.size>0
            options[:field_weights] = {
                :ip => 10000,
                :host => 400,
                :title => 50,
                :header    => 20,
                :body => 1
            }
          else
            options[:order] = "lastupdatetime DESC"
          end
=end
          @results = ThinkingSphinx.search Riddle::Query.escape(@query),options
        end
        @results.each{|r|
          @max_id = [@max_id, r.id.to_i].max
        }
        @max_id += 1
      }
    rescue ThinkingSphinx::SphinxError => e
      @error = e.to_s
    end
    [@error, @mode, @results, @tags]
  end
end
