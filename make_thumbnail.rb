require 'RMagick'

unless ARGV[0]
  puts 'usage: bundle exec ruby make_thumbnail.rb [ep]'
  exit 1
end

f_ep = "%03d" % ARGV[0]

src = "./img/#{f_ep}/"
dst = "./img/thumb/#{f_ep}/"

unless File.exists?(dst)
  FileUtils.mkdir_p(dst)
end

files = `ls #{src}`.split("\n")
files.each do |f|
  img = Magick::Image.read(src+f).first
  img.scale(0.3).write(dst + f)
  img.destroy!
  puts f
end

