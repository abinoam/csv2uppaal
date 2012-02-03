#!/usr/bin/env ruby
# Takes as argument *.csv protocol description file (exported using save as from
# OpenOffice using ; as delimiers and outputs *.xml and *.q files that can
# be opened in UPPAAL; then it tries to call the command line verifyta
# (UPPAAL engine) if possible and outputs a possible error trace in text format.
# Make sure that this file and csv2xml.sh are executable via chmod +x filename

require "optparse"
require 'rexml/document'

libdir = File.join(File.dirname(__FILE__), '..', 'lib')

$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include? libdir

require "c2u_optparse"
require "helper"
require "protocol_object"
require "parser"
require "render"
require "verifier"

include REXML

BIN_DIR=File.dirname(__FILE__)
OUT_DIR=File.dirname(Opt.filename)

# TODO: Check Mac GUI with the new tree layout

CSV2XML = File.join "#{BIN_DIR}", "csv2xml.sh"
TMP_XML = File.join "#{OUT_DIR}", "tmp.xml"

system "#{CSV2XML} \'#{Opt.filename}\' > \'#{TMP_XML}\'"

unless File.exist? TMP_XML
  raise ArgumentError, "File #{TMP_XML} doesn't exist."
end

protocol = Parser.parse(TMP_XML)
Render.renderize(protocol)

LINUX_VERIFYTA="/usr/local/bin/verifyta"
MAC_VERIFYTA="/Applications/verifyta"
LOCAL_VERIFYTA="./verifyta"

VERIFYTAS = [LINUX_VERIFYTA, MAC_VERIFYTA, LOCAL_VERIFYTA]

VERIFYTA = VERIFYTAS.find {|f| File.executable?(f) }

unless VERIFYTA
  puts <<EOS

Error: the script was not able to find the UPPAAL engine file verifyta in any of the following locations.
#{VERIFYTAS.inspect}
Check the README file in the tool distribution for info how to intall UPPAAL.
   
EOS

raise RuntimeError, "Couldn't find verifyta."

end

constraints = 
  Opt.fairness? ? 
    [:boundedness_under_fairness, :termination_under_fairness] :
    [:boundedness, :correctness, :termination, :deadlock_freeness]

constraints.each do |constraint|
  puts Verifier.new(constraint).verify 
end

puts Verifier.footer
