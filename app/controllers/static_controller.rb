require 'uri'
require 'net/http'

class StaticController < ApplicationController
  include StringStripper

  def classify
    desc = params[:description]
    desc = clean_string(desc)
    desc << ' '
    desc.insert(0, ' ')

    #look in application controller for this function
    matches = roboclassify(desc)
    if matches.empty?
      tfidf_matches = tfidf_classify(desc)
      tfidf_matches.each do |code_string|
        matches <<  Code.find(code_string.gsub(/\./, ''))
      end
    end

    @code_matches = []
    matches.each do |match|
      @code_matches << match unless @code_matches.index { |x| x.number == match.number }
    end

    if @code_matches.empty?
      @code_matches = "no matches"
      @json_response = "no matches"
    else
      @json_response = @code_matches.map {|m| {name: m.name, number: m.number,
                                            formatted_number: m.formatted_number}}
    end

    respond_to do |format|
      format.html { redirect_to controller: 'static',
                                action: 'robocode',
                                result: @code_matches
                  }
      format.json { render json: @json_response }
    end
  end

  def robocode
    results = params[:result]
    if results.nil?
      #no flash
    elsif results == "no matches"
      flash[:success] = "Robocoder could not classify this description"

    else
      result_string = ""
      results.each do |code_id|
        c = Code.find(code_id)
        result_string << "#{c.full_name} "
      end
      flash[:notice] = "Robocoder guesses " + result_string
    end
  end

end
