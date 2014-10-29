#!/usr/bin/ruby

IMGDIR = "/sample/thunder"
TOADDR = "test@sample.jp"
MAIL = "-S mailgw.sample.jp"

class THUNDER
  require 'date'
  require 'fileutils'
  require 'pp'
  require 'etc'

  def main
    png,con_png,imgdir = getimage
    level=checkimg(png,con_png,imgdir)
    sendmail(png,level)
  end

  def getimage
    ### get date and difine imagefilenames ###
    date = Time.now
    date_now = date.strftime("%Y%m%d%H%M")
    #date_now = '201211220300'
    date_rev = date_now.to_i / 10 * 10
    png="#{date_rev}-01.png"
    con_png="#{date_rev}-02.png"
    
    ### get imagefile ###
    pp "get [#{date_rev}-01.png]"
    y = date.strftime("%Y")
    m = date.strftime("%m")
    d = date.strftime("%d")
    imgdir = "#{IMGDIR}/#{y}/#{m}/#{d}"
    address="http://www.jma.go.jp/jp/radnowc/imgs/thunder/210/#{png}" #Please change parameters depending on subject area
    FileUtils.mkdir_p(imgdir) unless FileTest.exist?(imgdir)
    if FileTest.exist?("#{imgdir}/#{png}") 
      pp "==> image file already exist!"
    else
      `wget #{address} -P #{imgdir}`
    end

    return png,con_png,imgdir
  end

  def checkimg(png,con_png,imgdir)
    ##  information of color used when bad condition   ###
    ##    "#FAF500" => level 1                         ###
    ##    "#FF2800" => level 2                         ###
    ##    "#FFAA00" => level 3                         ###
    ##    "#C800FF" => level 4                         ###

    ### crop image and get information of color used ###
    `convert -crop 50x50+300+180 #{imgdir}/#{png} #{imgdir}/#{con_png}` #Please change parameters depending on subject area 
    img_info= `identify -verbose #{imgdir}/#{con_png} |grep Histogram: -A 10 |grep -E '#FAF500|#FF2800|#FFAA00|#C800FF' `
    level = 0
    if img_info.include?("#C800FF")
      level = 4
    elsif img_info.include?("#FFAA00")
      level = 3
    elsif img_info.include?("#FF2800")
      level = 2
    elsif img_info.include?("#FAF500")
      level = 1
    else
      level = 0
    end
    pp "LEVEL= #{level}"
    return level 

  end

  def sendmail(png,level)
    unless level == 0
      pp "sendmail"
      address="/jp/radnowc/imgs/thunder/210/#{png}"
      f = "#{IMGDIR}/4mail"
      txt = "\nPlease check jma's weather report!\n\n#{address}"
      File.write(f,txt)
      system("/bin/mailx #{MAIL} -s '[weather info]Please check![LEVEL#{level}]' #{TOADDR} < #{IMGDIR}/4mail")
    end

  end

end

thunder = THUNDER.new
thunder.main

