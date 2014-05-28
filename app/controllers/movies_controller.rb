require 'random_records'
require 'engtagger'
require 'lingua/stemmer'

class MoviesController < ApplicationController
  def index
    @pop = []
    movies = Movie.random(10)
    
    movies.each do |movie|
      mov = Hash.new
    mov['id']=movie.imdb_id.to_s
      if movie.title
        mov['title']=movie.title
      else
        mov['title'] = "Unknown"
      end
      if movie.plot_outline
        mov['desc']=movie.plot_outline
      else
        mov['desc']="Unavailable"
      end
      if movie.cover_url
        mov['img_url']=movie.cover_url
      end
      @pop << mov
    end

    respond_to do |format|
      format.html
    end
  end
  
  def search
    queryStr=params[:q]
    if queryStr and queryStr==''
      redirect_to '/'
      return
    end
    @q = params[:q]

    condition={}
    level_default = 1
    #presently QS not needed set
    qs_needed = 0 
    
    if queryStr and queryStr!=""
      if(qs_needed == 1 )
        query = []
        qs_out = []
        for i in 1..3
          query[i] = querysearch(queryStr,i)
          qs_out[i] = queryscope(query[i])
        end
        if(qs_out.uniq().length() == 1)
          level = qs_out.index(qs_out.uniq[0])
        elsif(qs_out.uniq.length() > 1)
          level = qs_out.index(qs_out.max)
        end
        puts 'level chosen is ', level+1
        puts query[level+1]
        condition[:subs] = query[level+1]
      else
        query = ""
        query = querysearch(queryStr,2)
        puts query
        condition[:subs] = query
      end
    end
    
    if params[:genre] and params[:genre]!=""
      condition[:genres]="*"+params[:genre]+"*"
    end
    
    results = Movie.search :conditions => condition, :page => params[:page], :per_page => 10, :match_mode => :extended

    @movies = results
    respond_to do |format|
      format.html
    end
  end

  def queryscope(queryStr)
    condition={}
    queryStr_new = queryStr.split(" ").delete_if {|words| words.include?("NEAR/")}
    queryStr = queryStr_new.join(" ")
    a = queryStr.split(" ")
    b = []
    newqueryStr = ""
    for i in 1..(a.length())
        b.concat(a.combination(i).to_a)
    end
    for combos in b
      if (combos.length() > 1)
        newqueryStr.concat("|")
        newqueryStr.concat(combos.join("*"))
      else
        if(newqueryStr == "")
          newqueryStr.concat(combos[0])
        else
          newqueryStr.concat("|"+combos[0])
        end
      end
    end

    condition[:subs] = newqueryStr
    qs_results = Movie.search :conditions => condition, :page => params[:page], :per_page => 10, :match_mode => :extended
    query_num = qs_results.total_entries
    total_docus = 19335
    if(query_num != 0)
      qs_param = "%.20f"%(Math.log10(total_docus/query_num))
      puts qs_param
    else
      return 0
    end
    return qs_param
  end

  def querysearch(queryStr,levelparam)

    if(levelparam == 1)
        return '"'+queryStr+'"'
    end

    tgr = EngTagger.new
    if(levelparam == 2)
      stemmer= Lingua::Stemmer.new
      rd = tgr.get_readable(queryStr)
      
      tokens = ['DET','WDET','WPS','EX','WP','CC','PP','PRP','PRPS']
      categories = []
      tokens.each do |tok|
        categories << rd.scan(/\s?(\S*?)\/#{tok}\s?/)
      end

      exception = []
      categories.each do |cat|
        cat.each do |elem|
          exception << elem[0]
        end
      end
      
      final = tgr.clean_text(queryStr)
      $j = 0
      $len = final.length()
      newqueryStr = []
      finalQuery = ""
      qsArray = []
      $oldj = -1
      #query construction with proximity
      while($j < $len ) do
        if(!exception.include?(final[$j]))
          if(final[$j] == "'ve")
            final[$j] = "have"
          elsif(final[$j] == "n't")
            final[$j] = "not"
          elsif(final[$j] == "'s")
            final[$j] = "is"
          elsif(final[$j] == "'ll")
            final[$j] = "will"
          elsif(final[$j] == "'re")
            final[$j] = "are"
                end
          qsArray.push(final[$j])
          out = Lingua.stemmer((final[$j]))
          #the strings are next to each other in main text
          if($j == $oldj + 1)
                #push directly without NEAR operator
                #module for stemming keywords
                  if(final[$j] != out)  
                      newqueryStr.push(final[$j]+"|"+out)
                  else
                      newqueryStr.push(final[$j])
                  end
          else
                $proxim = $j - $oldj
                if(newqueryStr != [])
                  newqueryStr.push("NEAR/#{$proxim}")
                end
                #stemming module
                if(final[$j] != out)  
                  newqueryStr.push(final[$j]+"|"+out)
                else
                  newqueryStr.push(final[$j])
                end
          end
          $oldj = $j
       end
       if($j == $len-1)
          break
       end
       $j = $j+1
      end
      if(finalQuery.last.include?("NEAR"))
        finalQuery.pop
      end
      finalQuery = newqueryStr.join(" ")
      if(finalQuery == "")
        querysearch(queryStr,levelparam+1)
      else
          return finalQuery
      end
    
    elsif(levelparam == 3)
      noun = tgr.get_nouns(tgr.add_tags(queryStr))
      noun_phrases = tgr.get_noun_phrases(tgr.add_tags(queryStr))
      nouns = []
      nounps = []
      for key in noun.keys
        nouns.push(key)
      end
      for key in noun_phrases.keys
        nounps.push(key)
      end
      #for noun query alone since we need proximity
      final = tgr.clean_text(queryStr)
      $len = final.length()
      $j = 0
      $oldj = -1
      newQuery = []
      while ($j < $len) do
      #without stemming cos it's noun
        if(nouns.include?(final[$j]))
          if($j == $oldj + 1)
            newQuery.push(final[$j])
          else
            $proxim = $j-$oldj-1
            if(newQuery != [])
              newQuery.push("NEAR/#{$proxim}")
            end
            newQuery.push(final[$j])
          end
        $oldj=$j
        end
        if($j = $len-1)
          break
        end
        $j = $j+1
      end
      #noun query
      if(newQuery!= [] && newQuery.last.include?("NEAR"))
        newQuery.pop
      end
      noun_query = newQuery.join(" ")
      #noun phrase query,no proximity needed
      nounps_query = nounps.join("|")
      if(noun_query != "")
        finalQuery =  noun_query + "|" + nounps_query 
      else
        finalQuery = nounps_query
      end
      if(finalQuery == "")
        querysearch(queryStr,levelparam+1)
      else
          return finalQuery
      end
  elsif(levelparam == 4)
      finalQuery = queryStr
      return finalQuery
  end
 end  #querysearch
end #class

