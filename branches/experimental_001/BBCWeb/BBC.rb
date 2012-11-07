#!/usr/bin/env ruby

require "Video"

PLAYER ='mplayer -prefer-ipv4 -noframedrop -dumpfile #{outfile}.rm -dumpstream #{infile}'
ENCODER='mencoder #{outfile}.rm -ovc lavc -oac pcm -o #{outfile}.avi'

class BBC
end

class BBCThree < BBC
  @@clip_template   =nil
  @@episode_template=nil

  def initialize(base_dir=".")
    @@clip_template=['rtsp://rmv8.bbc.net.uk/comedy/#{remote_name}/bb/#{clip}_16x9_bb.rm',
                     'rtsp://rmv8.bbc.net.uk/comedy/#{remote_name}/bb/#{remote_name}_#{clip}_16x9_bb.rm'] if @@clip_template.nil?
    @@episode_template=['rtsp://rmgeo.bbc.net.uk/bbcthree/#{remote_name}/bb/#{remote_name}_s#{series}_ep#{episode}_16x9_bb.rm'] if @@episode_template.nil?
    @base_dir=base_dir
  end

  def stream_episode(remote_name, local_name=remote_name.capitalize, series="00", episode="00", name=nil)
    name="Episode#{episode}" if name.nil?
    outfile   ="#{local_name}_#{series}x#{episode}_#{name}"
    file_dir  =File.join(@base_dir, "#{local_name}", "Season#{series}")
    final_file=File.join(@base_dir, "#{outfile}.avi")
    temp_file =File.join(@base_dir, "#{outfile}.rm")
    if File.exist?(File.join(@base_dir, "#{outfile}.avi")) then
      puts("#{outfile} exists. Skipping")
    else
      if File.exist?(File.join(@base_dir, "#{outfile}.rm")) then
        puts("#{outfile}.rm exists. Skipping download")
      else
        @@episode_template.each do |source|
          infile=eval('"'+source+'"')
          stream(infile, outfile)
        end
      end
      if File.exist?(File.join(@base_dir, "#{outfile}.rm")) then
        encode(infile)
        if File.exist?(File.join(@base_dir, "#{outfile}.avi")) then
          File.delete(File.join(@base_dir, "{outfile}.rm"))
        end
      end
    end
  end

  def stream_clip(remote_name, local_name=remote_name.capitalize, clip="00x00")
    @@clip_template.each do |source|
      outfile="#{local_name}_00x00_#{clip.capitalize}"
      infile =eval('"'+source+'"')
      stream(infile, outfile)
    end
  end

  def stream(infile, outfile)
    play_cmd  =eval('"'+PLAYER+'"')
    encode_cmd=eval('"'+ENCODER+'"')
    puts play_cmd, "\n", encode_cmd
  end
end

test=Video.new("/vault/nas01/video/episodes/Comedy_Shuffle/Season02/")
bbc =BBCThree.new("/vault/nas01/video/episodes")
bbc.stream_episode("comedy_shuffle", "Comedy_Shuffle", "01", "02")
bbc.stream_clip("cowards", "Cowards", "milk")
